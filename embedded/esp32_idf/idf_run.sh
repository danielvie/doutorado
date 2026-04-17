#!/bin/bash
# idf_run.sh - ESP-IDF shell wrapper for Task runner (macOS version)
# This script sets up the ESP-IDF environment and runs idf.py commands

set -e

# Configuration paths - macOS paths
ESP_IDF_PATH="/Users/danielvieira/esp/v5.5.1/esp-idf"
ESPRESSIF_TOOLS_PATH="/Users/danielvieira/.espressif"
PYTHON_VENV_PATH="$ESPRESSIF_TOOLS_PATH/python_env/idf5.5_py3.12_env"
TOOLCHAIN_PATH="$ESPRESSIF_TOOLS_PATH/tools/xtensa-esp-elf/esp-14.2.0_20241119"
ESP_CLANG_PATH="$ESPRESSIF_TOOLS_PATH/tools/esp-clang/esp-19.1.2_20250312/esp-clang/bin"

# Set environment variables
export IDF_PATH="$ESP_IDF_PATH"
export IDF_TOOLS_PATH="$ESPRESSIF_TOOLS_PATH"

# Helper function to add a directory to PATH only if not already present
# This prevents CMake from detecting environment changes and reconfiguring
add_to_path() {
    local dir="$1"
    if [ -z "$dir" ]; then
        return
    fi
    # Remove trailing slashes
    dir="${dir%/}"
    case ":$PATH:" in
        *":$dir:"*) ;;  # Already in PATH
        *) export PATH="$dir:$PATH" ;;
    esac
}

# Add toolchain to PATH (idempotent)
add_to_path "$TOOLCHAIN_PATH/xtensa-esp-elf/bin"

# Add ESP-IDF tools to PATH (idempotent)
add_to_path "$ESP_IDF_PATH/tools"

# Add Python venv to PATH (activate it, idempotent)
add_to_path "$PYTHON_VENV_PATH/bin"
add_to_path "$PYTHON_VENV_PATH"

# Set Python executable from venv
export PYTHON="$PYTHON_VENV_PATH/bin/python"

# Add esp-clang to PATH (for clangd, etc., idempotent)
add_to_path "$ESP_CLANG_PATH"

# Set ESP_ROM_ELF_DIR for gdbinit generation
export ESP_ROM_ELF_DIR="$ESPRESSIF_TOOLS_PATH/tools/esp-rom-elfs/20241011"

# Set IDF_PYTHON_ENV_PATH to avoid warnings
export IDF_PYTHON_ENV_PATH="$PYTHON_VENV_PATH"

# Ensure Python output is not buffered (prevents hanging)
export PYTHONUNBUFFERED="1"

# Function to auto-detect ESP32 serial port on macOS
find_esp_port() {
    # Common ESP32 USB-to-Serial chip patterns on macOS
    local patterns=("tty.usbserial" "tty.SLAB_USBtoUART" "tty.wchusbserial" "tty.usbmodem")

    for pattern in "${patterns[@]}"; do
        local port=$(ls /dev/ 2>/dev/null | grep "^$pattern" | head -n 1)
        if [ -n "$port" ]; then
            echo "/dev/$port"
            return
        fi
    done

    # Fallback: list any tty.usb* or cu.usb* devices
    local port=$(ls /dev/tty.usb* /dev/cu.usb* 2>/dev/null | head -n 1)
    if [ -n "$port" ]; then
        echo "$port"
        return
    fi

    echo ""
}

# Set default target and port if not already set
if [ -z "$IDF_TARGET" ]; then
    export IDF_TARGET="esp32"
fi

if [ -z "$ESPPORT" ]; then
    DETECTED_PORT=$(find_esp_port)
    if [ -n "$DETECTED_PORT" ]; then
        export ESPPORT="$DETECTED_PORT"
        echo -e "\033[32mAuto-detected ESP32 on $DETECTED_PORT\033[0m"
    else
        export ESPPORT="/dev/tty.usbserial-0001"
        echo -e "\033[33mNo ESP32 auto-detected, using default: /dev/tty.usbserial-0001\033[0m"
    fi
fi

# Verify Python and esptool version
PYTHON_VERSION=$($PYTHON --version 2>&1)
echo -e "\033[36mUsing Python: $PYTHON_VERSION\033[0m"

ESPTOOL_VERSION=$($PYTHON -m esptool version 2>&1 | grep "esptool.py" | head -n 1)
if [ -n "$ESPTOOL_VERSION" ]; then
    echo -e "\033[36mUsing $ESPTOOL_VERSION\033[0m"
fi

echo -e "\033[90mIDF_PATH: $IDF_PATH\033[0m"
echo -e "\033[90mTarget: $IDF_TARGET\033[0m"
echo -e "\033[90mPort: $ESPPORT\033[0m"
echo ""

# Build the idf.py command
IDF_PY_PATH="$ESP_IDF_PATH/tools/idf.py"

echo -e "\033[32mRunning: idf.py $*\033[0m"

# Execute idf.py with all arguments
$PYTHON "$IDF_PY_PATH" "$@"
