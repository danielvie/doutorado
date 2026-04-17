# Setup script for Windows - copies clangd and Zed configurations
# Usage: .\clangd.d\setup_clangd.ps1

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir

# Setup clangd config
$clangdSource = Join-Path $scriptDir "windows.yaml"
$clangdDest = Join-Path $projectDir ".clangd"

if (Test-Path $clangdSource) {
    Copy-Item -Path $clangdSource -Destination $clangdDest -Force
    Write-Host "âœ“ Copied Windows clangd config to .clangd" -ForegroundColor Green
    Write-Host "  Source: $clangdSource"
} else {
    Write-Error "Windows clangd config not found at $clangdSource"
    exit 1
}

# Setup Zed settings
$zedSource = Join-Path $projectDir ".zed.d" "settings-windows.json"
$zedDestDir = Join-Path $projectDir ".zed"
$zedDest = Join-Path $zedDestDir "settings.json"

if (Test-Path $zedSource) {
    if (-not (Test-Path $zedDestDir)) {
        New-Item -ItemType Directory -Path $zedDestDir -Force | Out-Null
    }
    Copy-Item -Path $zedSource -Destination $zedDest -Force
    Write-Host "âœ“ Copied Windows Zed settings to .zed/settings.json" -ForegroundColor Green
    Write-Host "  Source: $zedSource"
} else {
    Write-Warning "Windows Zed settings not found at $zedSource"
}

# Verify ESP-IDF environment
$espIdfPath = $env:IDF_PATH
if (-not $espIdfPath) {
    Write-Warning "IDF_PATH not set. Make sure ESP-IDF is properly configured."
}

Write-Host "`nSetup complete! Restart Zed to apply changes." -ForegroundColor Cyan
Write-Host "Next steps:"
Write-Host "1. Ensure xtensa-esp32-elf-gcc is in your PATH"
Write-Host "2. Verify clangd is working by opening a C/C++ file"
