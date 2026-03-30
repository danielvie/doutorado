# idf_run.ps1 - ESP-IDF PowerShell wrapper for Task runner
# This script sets up the ESP-IDF environment and runs idf.py commands

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$ErrorActionPreference = "Stop"

# Clear MSYS/MINGW environment variables to prevent ESP-IDF from detecting MSYS
# ESP-IDF 5.5+ no longer supports MSYS/Mingw environments
$env:MSYSTEM = $null
$env:MSYS = $null
$env:MINGW_PREFIX = $null
$env:MINGW_CHOST = $null
$env:MINGW_PACKAGE_PREFIX = $null
$env:ORIGINAL_PATH = $null
$env:PKG_CONFIG_PATH = $null
$env:ACLOCAL_PATH = $null
$env:MANPATH = $null

# Configuration paths - matching AGENT_CONTEXT.md
$EspIdfPath = "C:\Users\daniel\esp\v5.5.1\esp-idf"
$EspressifToolsPath = "C:\Users\daniel\.espressif"
$PythonVenvPath = "$EspressifToolsPath\python_env\idf5.5_py3.13_env"
$ToolchainPath = "$EspressifToolsPath\tools\xtensa-esp-elf\esp-14.2.0_20241119"
$EspClangPath = "$EspressifToolsPath\tools\esp-clang\esp-19.1.2_20250312\esp-clang\bin"

# Set environment variables
$env:IDF_PATH = $EspIdfPath
$env:IDF_TOOLS_PATH = $EspressifToolsPath

# Helper function to add a directory to PATH only if not already present
# This prevents CMake from detecting environment changes and reconfiguring
function Add-ToPath {
    param([string]$Dir)
    if (-not $Dir) { return }
    $normalizedDir = $Dir.TrimEnd('\').TrimEnd('/')
    $currentPaths = $env:PATH -split ';' | ForEach-Object { $_.Trim() }
    if ($normalizedDir -notin $currentPaths) {
        $env:PATH = "$Dir;$env:PATH"
    }
}

# Add toolchain to PATH (idempotent)
Add-ToPath "$ToolchainPath\xtensa-esp-elf\bin"

# Add ESP-IDF tools to PATH (idempotent)
Add-ToPath "$EspIdfPath\tools"

# Add Python venv to PATH (activate it, idempotent)
Add-ToPath "$PythonVenvPath\Scripts"
Add-ToPath "$PythonVenvPath"

# Set Python executable from venv
$env:PYTHON = "$PythonVenvPath\Scripts\python.exe"

# Add esp-clang to PATH (for clangd, etc., idempotent)
Add-ToPath "$EspClangPath"

# Set ESP_ROM_ELF_DIR for gdbinit generation
$env:ESP_ROM_ELF_DIR = "$EspressifToolsPath\tools\esp-rom-elfs\20241011"

# Set IDF_PYTHON_ENV_PATH to avoid warnings
$env:IDF_PYTHON_ENV_PATH = $PythonVenvPath

# Ensure Python output is not buffered (prevents hanging)
$env:PYTHONUNBUFFERED = "1"

# Function to auto-detect ESP32 serial port
function Find-EspPort {
    # Try to find ESP32 devices by checking USB VID/PID or friendly names
    $espDevices = Get-PnpDevice -Class Ports -ErrorAction SilentlyContinue | Where-Object { 
        $_.Name -match 'COM\d+' -and (
            $_.FriendlyName -match 'Silicon Labs' -or
            $_.FriendlyName -match 'CP210' -or
            $_.FriendlyName -match 'CH340' -or
            $_.FriendlyName -match 'FTDI' -or
            $_.FriendlyName -match 'USB Serial' -or
            $_.FriendlyName -match 'UART'
        )
    } | Select-Object -First 1
    
    if ($espDevices) {
        $port = ($espDevices.Name | Select-String 'COM\d+').Matches.Value
        return $port
    }
    
    # Fallback: check registry for serial ports
    $serialComm = Get-ItemProperty -Path "HKLM:\HARDWARE\DEVICEMAP\SERIALCOMM" -ErrorAction SilentlyContinue
    if ($serialComm) {
        $ports = $serialComm.PSObject.Properties | Where-Object { $_.Name -ne 'PSPath' -and $_.Name -ne 'PSParentPath' -and $_.Name -ne 'PSChildName' -and $_.Name -ne 'PSDrive' -and $_.Name -ne 'PSProvider' } | Select-Object -ExpandProperty Value
        if ($ports) {
            return $ports | Select-Object -First 1
        }
    }
    
    return $null
}

# Set default target and port if not already set
if (-not $env:IDF_TARGET) {
    $env:IDF_TARGET = "esp32"
}
if ([string]::IsNullOrEmpty($env:ESPPORT)) {
    $detectedPort = Find-EspPort
    if ($detectedPort) {
        $env:ESPPORT = $detectedPort
        Write-Host "Auto-detected ESP32 on $detectedPort" -ForegroundColor Green
    } else {
        $env:ESPPORT = "COM11"
        Write-Host "No ESP32 auto-detected, using default: COM11" -ForegroundColor Yellow
    }
}

# Verify Python and esptool version
$pythonVersion = & $env:PYTHON --version 2>&1
Write-Host "Using Python: $pythonVersion" -ForegroundColor Cyan

$esptoolVersion = & $env:PYTHON -m esptool version 2>&1 | Select-String "esptool.py" | Select-Object -First 1
if ($esptoolVersion) {
    Write-Host "Using $esptoolVersion" -ForegroundColor Cyan
}

Write-Host "IDF_PATH: $env:IDF_PATH" -ForegroundColor DarkGray
Write-Host "Target: $env:IDF_TARGET" -ForegroundColor DarkGray
Write-Host "Port: $env:ESPPORT" -ForegroundColor DarkGray
Write-Host ""

# Build the idf.py command
$idfPyPath = "$EspIdfPath\tools\idf.py"
$cmdArgs = $Arguments -join " "

Write-Host "Running: idf.py $cmdArgs" -ForegroundColor Green

# Execute idf.py with all arguments
# Build argument list properly
$argList = @($idfPyPath) + $Arguments

# Run idf.py
$process = Start-Process -FilePath $env:PYTHON -ArgumentList $argList -NoNewWindow -Wait -PassThru

# Exit with the same code as idf.py
exit $process.ExitCode