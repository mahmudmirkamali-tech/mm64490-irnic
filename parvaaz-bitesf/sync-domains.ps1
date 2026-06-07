# Sync domains from app.config.json to API/CORS files
$root = $PSScriptRoot
$cfgPath = Join-Path $root "app.config.json"
if (-not (Test-Path $cfgPath)) {
    Write-Host "app.config.json not found" -ForegroundColor Red
    exit 1
}

$cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
$origins = @($cfg.domains | ForEach-Object { "https://$_" })
$originsJson = ($origins | ForEach-Object { "'$_'" }) -join ",`n  "
$originsCsv = $origins -join ", "

# Cloudflare Pages function
$cfPath = Join-Path $root "functions\api\chat.js"
$cf = Get-Content $cfPath -Raw
$cf = $cf -replace '(?s)const ALLOWED_ORIGINS = \[.*?\];', "const ALLOWED_ORIGINS = [`n  $originsJson,`n  'http://localhost:3000',`n  'http://127.0.0.1:3000'`n];"
[System.IO.File]::WriteAllText($cfPath, $cf, [System.Text.UTF8Encoding]::new($false))

# Vercel function
$vercelPath = Join-Path $root "api\chat.js"
$vercel = Get-Content $vercelPath -Raw
$vercel = $vercel -replace "const ALLOWED = \[.*?\];", "const ALLOWED = [$originsJson];"
[System.IO.File]::WriteAllText($vercelPath, $vercel, [System.Text.UTF8Encoding]::new($false))

# Cloudflare _headers
$headersPath = Join-Path $root "_headers"
$headers = Get-Content $headersPath -Raw
$headers = $headers -replace 'Access-Control-Allow-Origin:.*', "Access-Control-Allow-Origin: $originsCsv"
[System.IO.File]::WriteAllText($headersPath, $headers, [System.Text.UTF8Encoding]::new($false))

Write-Host "Synced $($cfg.domains.Count) domains:" -ForegroundColor Green
$cfg.domains | ForEach-Object { Write-Host "  - $_" }
