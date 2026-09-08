#!/bin/bash
set -e

USAGE="Usage: $0 [game|web|all]
  game  — compile the ROM and open it in mGBA (default)
  web   — compile the ROM and copy it to web/ for the browser build
  all   — do both"

MODE="${1:-game}"

case "$MODE" in
    game|web|all) ;;
    -h|--help) echo "$USAGE"; exit 0 ;;
    *) echo "Unknown option: $MODE"; echo "$USAGE"; exit 1 ;;
esac

# ── Step 1: always generate song data and compile the ROM ─────────────────
case "$(uname -s)-$(uname -m)" in
    Linux-x86_64)  MOD2GBT=src/mod2gbt.linux-x86_64 ;;
    Darwin-arm64)  MOD2GBT=src/mod2gbt.mac-arm64 ;;
    *) echo "No mod2gbt binary bundled for $(uname -s)-$(uname -m)."
       echo "Build it from https://github.com/AntonioND/gbt-player (gb/legacy_gbdk/mod2gbt) and add it to src/."
       exit 1 ;;
esac

echo "=== Generating song data ==="
"$MOD2GBT" src/video_demo.mod song 2

echo "=== Building ROM ==="
make

# ── Step 2: mode-specific steps ───────────────────────────────────────────
if [[ "$MODE" == "game" || "$MODE" == "all" ]]; then
    echo "=== Running emulator ==="
    case "$(uname -s)" in
        Darwin) /Applications/mGBA.app/Contents/MacOS/mGBA my_game.gb ;;
        *)      mgba-qt my_game.gb ;;
    esac
fi

if [[ "$MODE" == "web" || "$MODE" == "all" ]]; then
    echo "=== Copying ROM to web/ ==="
    make web

    if [[ ! -f web/emulatorjs/loader.js ]]; then
        echo "=== Downloading EmulatorJS bundle (first-time setup) ==="
        make download-emulatorjs
    fi

    echo "=== Web build ready — serving at http://localhost:8000 ==="
    echo "    Press Ctrl+C to stop."
    cd web && python3 -m http.server 8000
fi
