# Parvaaz PWA - Local development server
# Serves static files + proxies AI chat to Anthropic API

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Port = 3000
$Root = $PSScriptRoot
$ConfigPath = Join-Path $Root "config.json"
$AppConfigPath = Join-Path $Root "app.config.json"

function Get-AllowedOrigins {
    $local = @("http://localhost:$Port", "http://127.0.0.1:$Port")
    if (Test-Path $AppConfigPath) {
        $app = Get-Content $AppConfigPath -Raw | ConvertFrom-Json
        $remote = @($app.domains | ForEach-Object { "https://$_" })
        return $remote + $local
    }
    return @("http://localhost:$Port", "http://127.0.0.1:$Port")
}

$script:AllowedOrigins = Get-AllowedOrigins

function Get-ApiKey {
    if (Test-Path $ConfigPath) {
        $cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        if ($cfg.anthropic_api_key -and $cfg.anthropic_api_key -ne "YOUR_API_KEY_HERE") {
            return $cfg.anthropic_api_key
        }
    }
    return $env:ANTHROPIC_API_KEY
}

function Get-MimeType($path) {
    $ext = [System.IO.Path]::GetExtension($path).ToLower()
    switch ($ext) {
        ".html" { return "text/html; charset=utf-8" }
        ".js"   { return "application/javascript; charset=utf-8" }
        ".json" { return "application/json; charset=utf-8" }
        ".css"  { return "text/css; charset=utf-8" }
        ".svg"  { return "image/svg+xml" }
        ".png"  { return "image/png" }
        ".ico"  { return "image/x-icon" }
        default { return "application/octet-stream" }
    }
}

function Send-Response($ctx, $status, $body, $contentType) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
    $ctx.Response.StatusCode = $status
    $ctx.Response.ContentType = $contentType
    $ctx.Response.ContentLength64 = $bytes.Length
    $origin = $ctx.Request.Headers["Origin"]
    if ($script:AllowedOrigins -contains $origin) { $ctx.Response.Headers.Add("Access-Control-Allow-Origin", $origin) }
    else { $ctx.Response.Headers.Add("Access-Control-Allow-Origin", "*") }
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $ctx.Response.Close()
}

function Send-File($ctx, $filePath) {
    if (-not (Test-Path $filePath)) {
        Send-Response $ctx 404 '{"error":"Not found"}' "application/json"
        return
    }
    $bytes = [System.IO.File]::ReadAllBytes($filePath)
    $ctx.Response.StatusCode = 200
    $ctx.Response.ContentType = Get-MimeType $filePath
    $ctx.Response.ContentLength64 = $bytes.Length
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $ctx.Response.Close()
}

function Handle-ApiChat($ctx) {
    $reader = New-Object System.IO.StreamReader($ctx.Request.InputStream, $ctx.Request.ContentEncoding)
    $body = $reader.ReadToEnd()
    $reader.Close()

    $apiKey = Get-ApiKey
    if (-not $apiKey) {
        Send-Response $ctx 500 '{"error":"API key not configured. Edit config.json and add your anthropic_api_key."}' "application/json"
        return
    }

    try {
        $req = [System.Net.WebRequest]::Create("https://api.anthropic.com/v1/messages")
        $req.Method = "POST"
        $req.ContentType = "application/json"
        $req.Headers.Add("x-api-key", $apiKey)
        $req.Headers.Add("anthropic-version", "2023-06-01")

        $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
        $req.ContentLength = $bodyBytes.Length
        $stream = $req.GetRequestStream()
        $stream.Write($bodyBytes, 0, $bodyBytes.Length)
        $stream.Close()

        $resp = $req.GetResponse()
        $respReader = New-Object System.IO.StreamReader($resp.GetResponseStream())
        $respBody = $respReader.ReadToEnd()
        $respReader.Close()

        Send-Response $ctx 200 $respBody "application/json"
    }
    catch [System.Net.WebException] {
        $errResp = $_.Exception.Response
        if ($errResp) {
            $errReader = New-Object System.IO.StreamReader($errResp.GetResponseStream())
            $errBody = $errReader.ReadToEnd()
            $errReader.Close()
            Write-Host "  [API] Anthropic error $($errResp.StatusCode): $errBody" -ForegroundColor Red
            Send-Response $ctx ([int]$errResp.StatusCode) $errBody "application/json"
        } else {
            Write-Host "  [API] Connection failed: $($_.Exception.Message)" -ForegroundColor Red
            $msg = $_.Exception.Message -replace '"', '\"'
            Send-Response $ctx 502 "{`"error`":`"Failed to reach Anthropic API: $msg`"}" "application/json"
        }
    }
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Start()

Write-Host ""
Write-Host "  ========================================" -ForegroundColor Yellow
Write-Host "  Parvaaz PWA - Server running" -ForegroundColor Yellow
Write-Host "  ========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Open in browser: http://localhost:$Port" -ForegroundColor Green
Write-Host "  Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

$apiKey = Get-ApiKey
if (-not $apiKey) {
    Write-Host "  WARNING: API key not set!" -ForegroundColor Red
    Write-Host "  Edit config.json and add your anthropic_api_key" -ForegroundColor Red
    Write-Host ""
} elseif ($apiKey -notmatch '^sk-ant-') {
    Write-Host "  WARNING: API key format looks invalid (expected sk-ant-...)" -ForegroundColor Red
    Write-Host "  Get a key from https://console.anthropic.com/" -ForegroundColor Red
    Write-Host ""
}

try {
    while ($listener.IsListening) {
        $ctx = $listener.GetContext()
        $url = $ctx.Request.Url.LocalPath
        $method = $ctx.Request.HttpMethod

        # CORS preflight
        if ($method -eq "OPTIONS") {
            $ctx.Response.StatusCode = 204
            $origin = $ctx.Request.Headers["Origin"]
    if ($script:AllowedOrigins -contains $origin) { $ctx.Response.Headers.Add("Access-Control-Allow-Origin", $origin) }
    else { $ctx.Response.Headers.Add("Access-Control-Allow-Origin", "*") }
            $ctx.Response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
            $ctx.Response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")
            $ctx.Response.Close()
            continue
        }

        if ($url -eq "/api/chat" -and $method -eq "POST") {
            Handle-ApiChat $ctx
            continue
        }

        # Static files
        $relPath = $url.TrimStart("/")
        if ($relPath -eq "" -or $relPath -eq "/") { $relPath = "index.html" }
        $filePath = Join-Path $Root ($relPath -replace "/", [IO.Path]::DirectorySeparatorChar)

        # Security: prevent path traversal
        $fullRoot = [System.IO.Path]::GetFullPath($Root)
        $fullFile = [System.IO.Path]::GetFullPath($filePath)
        if (-not $fullFile.StartsWith($fullRoot)) {
            Send-Response $ctx 403 '{"error":"Forbidden"}' "application/json"
            continue
        }

        Send-File $ctx $filePath
    }
}
finally {
    $listener.Stop()
}
