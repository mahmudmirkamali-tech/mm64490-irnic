# Quick setup: API key + domains
param(
    [Parameter(Mandatory = $true)]
    [string]$ApiKey,
    [Parameter(Mandatory = $true)]
    [string[]]$Domains,
    [string]$PrimaryDomain = ""
)

$root = $PSScriptRoot
if (-not $PrimaryDomain) { $PrimaryDomain = ($Domains | Where-Object { $_ -notlike "www.*" } | Select-Object -First 1) }

# Save API key (local only — gitignored)
@{
    anthropic_api_key = $ApiKey
} | ConvertTo-Json | Set-Content (Join-Path $root "config.json") -Encoding UTF8

# Save domains
@{
    primaryDomain = $PrimaryDomain
    domains       = $Domains
    siteName      = "موسسه محمود | پلتفرم پرواز"
} | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $root "app.config.json") -Encoding UTF8

& (Join-Path $root "sync-domains.ps1")

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host "  Primary domain: $PrimaryDomain"
Write-Host "  Domains: $($Domains -join ', ')"
Write-Host ""
Write-Host "Local:  start.bat  ->  http://localhost:3000"
Write-Host "Cloud:  set ANTHROPIC_API_KEY in Cloudflare Pages + deploy"
