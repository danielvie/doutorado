#!/bin/bash
# Setup script for cross-platform clangd and Zed configuration
# Usage: ./.clangd.d/setup_clangd.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLANGD_CONFIG_DIR="$SCRIPT_DIR"
ZED_CONFIG_DIR="$PROJECT_DIR/.zed.d"
ZED_TARGET_DIR="$PROJECT_DIR/.zed"

detect_os() {
    case "$(uname -s)" in
        Darwin*)    echo "macos";;
        Linux*)     echo "linux";;
        CYGWIN*|MINGW*|MSYS*) echo "windows";;
        *)          echo "unknown";;
    esac
}

setup_clangd_config() {
    local os="$1"
    local source_file="$CLANGD_CONFIG_DIR/$os.yaml"

    # Fallback to macos for linux if no linux-specific config exists
    if [[ "$os" == "linux" && ! -f "$source_file" ]]; then
        source_file="$CLANGD_CONFIG_DIR/macos.yaml"
    fi

    if [[ ! -f "$source_file" ]]; then
        echo "Error: No clangd config found for OS: $os"
        echo "Available configs:"
        ls -1 "$CLANGD_CONFIG_DIR"/*.yaml 2>/dev/null || echo "  (none)"
        return 1
    fi

    cp "$source_file" "$PROJECT_DIR/.clangd"
    echo "✓ Set up .clangd for $os"
    echo "  Source: $source_file"
}

setup_zed_config() {
    local os="$1"
    local zed_os="$os"

    # Use macos settings for linux
    if [[ "$os" == "linux" ]]; then
        zed_os="macos"
    fi

    local source_file="$ZED_CONFIG_DIR/settings-$zed_os.json"
    local target_file="$ZED_TARGET_DIR/settings.json"

    if [[ ! -f "$source_file" ]]; then
        echo "Warning: No Zed settings found for OS: $zed_os"
        return 0
    fi

    mkdir -p "$ZED_TARGET_DIR"
    cp "$source_file" "$target_file"
    echo "✓ Set up .zed/settings.json for $os"
    echo "  Source: $source_file"
    echo "  Target: $target_file"
}

main() {
    local os
    os=$(detect_os)

    echo "Detected OS: $os"
    echo ""

    if [[ "$os" == "unknown" ]]; then
        echo "Error: Could not detect operating system"
        exit 1
    fi

    setup_clangd_config "$os"
    setup_zed_config "$os"

    echo ""
    echo "Next steps:"
    echo "1. Ensure xtensa-esp32-elf-gcc is in your PATH"
    echo "2. Reload Zed or restart your editor"
    echo "3. Verify clangd is working by opening a C/C++ file"
}

main "$@"
