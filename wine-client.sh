#!/bin/bash -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Defaults
GTA_PATH="${GTA_PATH:-$HOME/Documents/GTA San Andreas}"
OUTPUT_DIR="${OUTPUT_DIR:-$SCRIPT_DIR/Bin}"
BUILD_CONFIG="release"
DO_BUILD=true
DO_RUN=true
MSBUILD="${MSBUILDPATH:-$HOME/msvc-wine/msvc/bin/x64/msbuild}"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Build and/or run the MTA:SA client under Wine.

Options:
  --gta-path PATH        Path to GTA:SA installation (default: \$HOME/Documents/GTA San Andreas)
  --output PATH          Output directory (default: Bin/)
  --config debug|release Build configuration (default: release)
  --build-only           Build the client, don't run
  --run-only             Run the client, skip build
  --skip-build           Alias for --run-only
  --help                 Show this help

Environment variables:
  MSBUILDPATH            Path to MSBuild wrapper (default: ~/msvc-wine/msvc/bin/x64/msbuild)
  DXSDK_DIR              Path to DirectX SDK root (default: \$SCRIPT_DIR)
EOF
    exit 0
}

while [ $# -gt 0 ]; do
    case "$1" in
        --gta-path)     GTA_PATH="$2"; shift 2 ;;
        --output)       OUTPUT_DIR="$2"; shift 2 ;;
        --config)       BUILD_CONFIG="$2"; shift 2 ;;
        --build-only)   DO_RUN=false; shift ;;
        --run-only|--skip-build) DO_BUILD=false; shift ;;
        --help)         usage ;;
        *)              echo "Error: Unknown option $1" >&2; usage ;;
    esac
done

# Validate config
case "$BUILD_CONFIG" in
    debug|release) ;;
    *) echo "Error: Invalid config '$BUILD_CONFIG'. Use 'debug' or 'release'." >&2; exit 1 ;;
esac

# Convert to MSBuild convention
case "$BUILD_CONFIG" in
    debug)   MSBUILD_CONFIG=Debug ;;
    release) MSBUILD_CONFIG=Release ;;
esac

# Check prerequisites
if [ ! -f "$MSBUILD" ]; then
    echo "Error: MSBuild not found at '$MSBUILD'."
    echo "Set MSBUILDPATH to your msvc-wine msbuild script."
    exit 1
fi

# --- Build ---

if [ "$DO_BUILD" = true ]; then
    echo "=== Step 1: Generate project files ==="
    cd "$SCRIPT_DIR"
    wine win-create-projects.bat < /dev/null 2>/dev/null || true

    echo "=== Step 2: Strip PostBuildEvent from vcxproj files ==="
    for f in "$SCRIPT_DIR/Build/"*.vcxproj; do
        sed -i '/<PostBuildEvent>/,/<\/PostBuildEvent>/d' "$f"
    done

    echo "=== Step 2b: Patch cryptopp.vcxproj to disable MASM (XamlTaskFactory not available under msvc-wine) ==="
    # The server deathmatch mod links against cryptopp, which uses MASM (x64 assembly)
    # for crypto optimizations.  msvc-wine's .NET 4.0 does not ship XamlTaskFactory,
    # so we remove the MASM items and use the C++ fallback instead.
    python3 -c "
import re, sys
path = '$SCRIPT_DIR/Build/cryptopp.vcxproj'
try:
    with open(path) as f: c = f.read()
    c = c.replace('<Import Project=\"\$(VCTargetsPath)\\\\BuildCustomizations\\\\masm.props\" />\n', '')
    c = c.replace('<Import Project=\"\$(VCTargetsPath)\\\\BuildCustomizations\\\\masm.targets\" />\n', '')
    c = re.sub(r'  </ItemGroup>\n  <ItemGroup>\n    <Masm Include[^>]+>.*?</ItemGroup>\n', '  </ItemGroup>\n', c, flags=re.DOTALL)
    c = c.replace('CRYPTOPP_DISABLE_SSSE3;', 'CRYPTOPP_DISABLE_SSSE3;CRYPTOPP_DISABLE_ASM;')
    with open(path, 'w') as f: f.write(c)
    print('cryptopp MASM patched OK')
except FileNotFoundError:
    print('cryptopp.vcxproj not found, skipping MASM patch')
" 2>/dev/null || true

    echo "=== Step 3: Ensure DirectX and afxres.h stubs ==="
    # The D3DX9 headers are expected in Include/.  Also create a minimal afxres.h
    # stub for the RC compiler (MFC is not available under msvc-wine).
    if [ ! -f "$SCRIPT_DIR/Include/afxres.h" ]; then
        mkdir -p "$SCRIPT_DIR/Include"
        printf '#define IDC_STATIC  (-1)\n#include <windows.h>\n' > "$SCRIPT_DIR/Include/afxres.h"
    fi

    echo "=== Step 4: Build client projects ==="
    BUILD_PROJECTS=(
        "Client Launcher"
        "Client Core"
        "GUI"
        "Game SA"
        "Multiplayer SA"
        "Loader"
        "Loader Proxy"
        "Client Deathmatch"
        "Client Webbrowser"
        "CEFLauncher"
        "CEFLauncher DLL"
    )

    cd "$SCRIPT_DIR/Build"
    for project in "${BUILD_PROJECTS[@]}"; do
        echo "  Building $project..."
        DXSDK_DIR="${DXSDK_DIR:-$SCRIPT_DIR}" "$MSBUILD" "$project.vcxproj" \
            -property:Configuration="$MSBUILD_CONFIG" \
            -property:Platform=Win32 \
            -maxcpucount \
            -verbosity:minimal 2>&1 | grep -E "error|Warning|Warning.*=>|-> |Build succeeded|Build FAILED" || true
    done

    echo "=== Step 5: Build server components (x64) for Host Game ==="
    SERVER_PROJECTS=(
        "Launcher"
        "Core"
        "XML"
        "Lua_Server"
        "Deathmatch"
    )
    for project in "${SERVER_PROJECTS[@]}"; do
        echo "  Building $project (x64)..."
        DXSDK_DIR="${DXSDK_DIR:-$SCRIPT_DIR}" "$MSBUILD" "$project.vcxproj" \
            -property:Configuration="$MSBUILD_CONFIG" \
            -property:Platform=x64 \
            -maxcpucount \
            -verbosity:minimal 2>&1 | grep -E "error|Warning.*=>|-> |Build succeeded|Build FAILED" || true
    done

    echo "=== Step 6: Copy CEF runtime files ==="
    mkdir -p "$OUTPUT_DIR/mta/cef/locales"
    cp -n "$SCRIPT_DIR/vendor/cef3/cef/Release/"*.dll "$OUTPUT_DIR/mta/" 2>/dev/null || true
    cp -n "$SCRIPT_DIR/vendor/cef3/cef/Resources/icudtl.dat" "$OUTPUT_DIR/mta/" 2>/dev/null || true
    cp -n "$SCRIPT_DIR/vendor/cef3/cef/Resources/"*.pak "$OUTPUT_DIR/mta/" 2>/dev/null || true
    cp -n "$SCRIPT_DIR/vendor/cef3/cef/Resources/locales/"* "$OUTPUT_DIR/mta/cef/locales/" 2>/dev/null || true

    echo "=== Step 7: Install client data files ==="
    cp -rn "$SCRIPT_DIR/Shared/data/MTA San Andreas/"* "$OUTPUT_DIR/" 2>/dev/null || true
fi

# --- Runtime setup (required for both build and run) ---

echo "=== Runtime: Ensure dxerr.lib stub ==="
# dxerr.lib was part of the legacy DirectX SDK; the GUI project links it but
# doesn't use any of its symbols — a copy of d3dx9.lib works as a stub.
if [ -f "$SCRIPT_DIR/Lib/x86/d3dx9.lib" ] && [ ! -f "$SCRIPT_DIR/Lib/x86/dxerr.lib" ]; then
    cp "$SCRIPT_DIR/Lib/x86/d3dx9.lib" "$SCRIPT_DIR/Lib/x86/dxerr.lib"
fi

echo "=== Runtime: Install client data files ==="
mkdir -p "$OUTPUT_DIR/mta/cef/locales"
# Data files (copied from the source tree; skip if already present)
if [ ! -f "$OUTPUT_DIR/MTA/bass.dll" ]; then
    cp -r "$SCRIPT_DIR/Shared/data/MTA San Andreas/"* "$OUTPUT_DIR/" 2>/dev/null || true
fi
# CEF runtime files (no-clobber: the reverse MTA→mta merge below will overwrite
# the correct data-file versions, so we must not revert them on re-run)
cp -n "$SCRIPT_DIR/vendor/cef3/cef/Release/"*.dll "$OUTPUT_DIR/mta/" 2>/dev/null || true
cp -n "$SCRIPT_DIR/vendor/cef3/cef/Resources/icudtl.dat" "$OUTPUT_DIR/mta/" 2>/dev/null || true
cp -n "$SCRIPT_DIR/vendor/cef3/cef/Resources/"*.pak "$OUTPUT_DIR/mta/" 2>/dev/null || true
cp -n "$SCRIPT_DIR/vendor/cef3/cef/Resources/locales/"* "$OUTPUT_DIR/mta/cef/locales/" 2>/dev/null || true

echo "=== Runtime: Stage runtime files ==="

mkdir -p "$OUTPUT_DIR/MTA"

# Merge DLLs from mta/ into MTA/ (case-sensitivity fix: Linux FS is case-sensitive,
# premake outputs to lowercase mta/ but the launcher looks in uppercase MTA/)
if [ -d "$OUTPUT_DIR/mta" ]; then
    cp -rn "$OUTPUT_DIR/mta/"* "$OUTPUT_DIR/MTA/" 2>/dev/null || true
fi

# Download netc.dll (network component, ships as a prebuilt binary).
# The launcher (Utils.cpp:1344) loads it from the lowercase mta/ directory,
# while the proxy loader (loader-proxy/main.cpp:413) loads it from uppercase MTA/.
# Put it in both to cover both code paths on case-sensitive filesystems.
if [ ! -f "$OUTPUT_DIR/MTA/netc.dll" ]; then
    wget -q "https://mirror-cdn.multitheftauto.com/bdata/netc.dll" -O "$OUTPUT_DIR/MTA/netc.dll" || true
fi
if [ ! -f "$OUTPUT_DIR/mta/netc.dll" ]; then
    cp -n "$OUTPUT_DIR/MTA/netc.dll" "$OUTPUT_DIR/mta/netc.dll" 2>/dev/null || true
fi

# Ensure pthread.dll is in MTA/ (netc.dll depends on it)
if [ -f "$OUTPUT_DIR/mta/pthread.dll" ] && [ ! -f "$OUTPUT_DIR/MTA/pthread.dll" ]; then
    cp "$OUTPUT_DIR/mta/pthread.dll" "$OUTPUT_DIR/MTA/pthread.dll"
fi

# Also merge MTA/ → mta/ so the integrity check (MainFunctions.cpp:1664) can find
# its files in the lowercase mta/ directory. Clobber because the data files in
# MTA/ have correct hashes (especially d3dcompiler_47.dll — CEF ships its own
# version with a different hash that fails the integrity check).
cp -r "$OUTPUT_DIR/MTA/"* "$OUTPUT_DIR/mta/" 2>/dev/null || true

# Register bundled fonts in Wine so CGUI can find them.
# CGUI_Impl.cpp creates three Window fonts via CreateFntFromWinFont:
#   tahoma.ttf / tahomabd.ttf / verdana.ttf  — none shipped with the data files.
# We bundle them into Wine's fonts dir and register under the expected key names.
WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
WINE_FONTS="$WINEPREFIX/drive_c/windows/Fonts"
mkdir -p "$WINE_FONTS"
for fontfile in sans.ttf unifont.ttf; do
    if [ -f "$OUTPUT_DIR/MTA/cgui/$fontfile" ] && [ ! -f "$WINE_FONTS/$fontfile" ]; then
        cp "$OUTPUT_DIR/MTA/cgui/$fontfile" "$WINE_FONTS/$fontfile"
    fi
done
# Pre-register so the first two lookups in CreateFntFromWinFont succeed
cat > /tmp/mta_fonts.reg << 'REGEOF'
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts]
"Tahoma (TrueType)"="sans.ttf"
"Tahoma Bold (TrueType)"="sans.ttf"
"Verdana (TrueType)"="sans.ttf"
REGEOF
wine regedit /S /tmp/mta_fonts.reg 2>/dev/null

# --- Run ---

if [ "$DO_RUN" = true ]; then
    echo "=== Run: Launch MTA client under Wine ==="

    # Derive version string from source (e.g. "1.7")
    MTA_VER_MAJOR=$(grep -m1 'MTASA_VERSION_MAJOR' "$SCRIPT_DIR/Shared/sdk/version.h" | grep -oP '\d+')
    MTA_VER_MINOR=$(grep -m1 'MTASA_VERSION_MINOR' "$SCRIPT_DIR/Shared/sdk/version.h" | grep -oP '\d+')
    MTA_VERSION="${MTA_VER_MAJOR}.${MTA_VER_MINOR}"

    # Convert to Wine path (Z: drive prefix)
    GTA_PATH_WINE="Z:$(echo "$GTA_PATH" | sed 's|/|\\\\|g')"
    OUTPUT_DIR_WINE="Z:$(echo "$OUTPUT_DIR" | sed 's|/|\\\\|g')"

    # Create the data directories that _ProcessLayoutChecks expects
    WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
    MTA_DATA_DIR="$WINEPREFIX/drive_c/ProgramData/MTA San Andreas All"
    mkdir -p "$MTA_DATA_DIR/$MTA_VERSION" "$MTA_DATA_DIR/Common"

    # Set up registry so the launcher can find GTA:SA
    cat > /tmp/mta_setup.reg << REGEOF
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\Software\Multi Theft Auto: San Andreas All\Common]
"GTA:SA Path"="${GTA_PATH_WINE}"

[HKEY_LOCAL_MACHINE\Software\Multi Theft Auto: San Andreas All\${MTA_VERSION}]
"Last Run Location"="${OUTPUT_DIR_WINE}"
"Last Install Location"="${OUTPUT_DIR_WINE}"
REGEOF
    wine regedit /S /tmp/mta_setup.reg 2>/dev/null

    cd "$OUTPUT_DIR"
    echo "Launching from $OUTPUT_DIR..."
    wine "Multi Theft Auto.exe" 2>/dev/null
fi
