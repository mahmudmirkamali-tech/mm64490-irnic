# Upload project to NetAfraz / irwebspace hosting
param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
$HostingPath = Join-Path $Root "hosting.config.json"
$LocalConfigPath = Join-Path $Root "config.json"

if (-not (Test-Path $HostingPath)) {
    Write-Host "hosting.config.json not found" -ForegroundColor Red
    exit 1
}

$hosting = Get-Content $HostingPath -Raw | ConvertFrom-Json
$ftp = $hosting.ftp

if (-not $ftp.password -and -not $DryRun) {
    Write-Host "FTP password is empty in hosting.config.json" -ForegroundColor Red
    Write-Host "Add cPanel FTP password and run again." -ForegroundColor Yellow
    exit 1
}

$secretsPath = Join-Path $Root "api\secrets.php"
$localCfg = $null
if (Test-Path $LocalConfigPath) {
    $localCfg = Get-Content $LocalConfigPath -Raw | ConvertFrom-Json
}
$key = $localCfg.anthropic_api_key
if ($key -and $key -ne "YOUR_API_KEY_HERE") {
    $escaped = $key -replace "'", "\'"
    $php = "<?php`r`nreturn [`r`n    'anthropic_api_key' => '$escaped',`r`n];`r`n"
    [System.IO.File]::WriteAllText($secretsPath, $php, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "api/secrets.php prepared from config.json" -ForegroundColor Green
} elseif (-not (Test-Path $secretsPath)) {
    Copy-Item (Join-Path $Root "api\secrets.example.php") $secretsPath
    Write-Host "WARNING: No API key in config.json" -ForegroundColor Yellow
}

$excludeFiles = @(
    'server.ps1', 'start.bat', 'setup.ps1', 'sync-domains.ps1', 'generate-icons.ps1',
    'deploy-ftp.ps1', 'hosting.config.json', 'hosting.config.example.json', 'config.json',
    'package.json', 'wrangler.toml', 'vercel.json', '.gitignore',
    'DEPLOY.md', 'DEPLOY-HOST.md', 'DNS.md', 'README.md',
    'api\chat.js', 'api\secrets.example.php',
    'parvaaz-bitesf.zip', '_headers'
)

$excludeDirs = @('functions', 'node_modules', '.git', '.wrangler')

function Get-UploadFiles {
    $files = @()
    Get-ChildItem -Path $Root -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($Root.Length + 1).Replace('\', '/')
        $skip = $false
        foreach ($d in $excludeDirs) {
            if ($rel.StartsWith($d.Replace('\', '/') + '/')) { $skip = $true; break }
        }
        foreach ($ex in $excludeFiles) {
            if ($rel -eq $ex.Replace('\', '/')) { $skip = $true; break }
        }
        if (-not $skip) { $files += $_ }
    }
    return $files
}

function Ensure-FtpDir($ftpUri, $cred, $dirPath) {
    if ($dirPath -eq '' -or $dirPath -eq '/') { return }
    $parts = $dirPath.Trim('/').Split('/')
    $current = ''
    foreach ($p in $parts) {
        $current += "/$p"
        try {
            $req = [System.Net.FtpWebRequest]::Create($ftpUri + $current)
            $req.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory
            $req.Credentials = $cred
            $req.GetResponse().Close()
        } catch { }
    }
}

function Upload-FtpFile($localFile, $remoteRel, $ftpUri, $cred) {
    $remoteDir = [System.IO.Path]::GetDirectoryName($remoteRel).Replace('\', '/')
    if ($remoteDir) { Ensure-FtpDir $ftpUri $cred ("/" + $remoteDir) }
    $uri = $ftpUri + "/" + $remoteRel
    $req = [System.Net.FtpWebRequest]::Create($uri)
    $req.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
    $req.Credentials = $cred
    $req.UseBinary = $true
    $req.UsePassive = $true
    $bytes = [System.IO.File]::ReadAllBytes($localFile.FullName)
    $req.ContentLength = $bytes.Length
    $stream = $req.GetRequestStream()
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Close()
    $req.GetResponse().Close()
}

$scheme = if ($ftp.useSsl) { "ftps" } else { "ftp" }
$ftpUri = $scheme + "://" + $ftp.host + $ftp.remotePath
$cred = New-Object System.Net.NetworkCredential($ftp.username, $ftp.password)

$files = Get-UploadFiles
Write-Host ""
Write-Host ("Deploy to " + $hosting.domain + " via " + $ftpUri) -ForegroundColor Yellow
Write-Host ("Files: " + $files.Count) -ForegroundColor Gray
Write-Host ""

if ($DryRun) {
    foreach ($f in $files) {
        $rel = $f.FullName.Substring($Root.Length + 1).Replace('\', '/')
        Write-Host ("  " + $rel)
    }
    exit 0
}

$ok = 0
$fail = 0
foreach ($f in $files) {
    $rel = $f.FullName.Substring($Root.Length + 1).Replace('\', '/')
    try {
        Upload-FtpFile $f $rel $ftpUri $cred
        Write-Host ("  OK  " + $rel) -ForegroundColor Green
        $ok++
    } catch {
        Write-Host ("  FAIL " + $rel + " - " + $_.Exception.Message) -ForegroundColor Red
        $fail++
    }
}

Write-Host ""
Write-Host ("Done: " + $ok + " uploaded, " + $fail + " failed")
if ($fail -eq 0) {
    Write-Host ("Site: https://" + $hosting.domain) -ForegroundColor Cyan
}
