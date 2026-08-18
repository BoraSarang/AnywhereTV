#!/bin/bash
set -euo pipefail

MODE="${1:-debug}"

APP_NAME="AnywhereTV Channel Editor"
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$HOME/Applications/$APP_NAME.app"

GREEN='\033[0;32m'; NC='\033[0m'
log() { echo -e "${GREEN}[build-cm]${NC} $1"; }

cd "$APP_DIR"

log "flutter analyze"
if flutter analyze | grep -qE ' error '; then
  echo "[build-cm] analyze errors found"
  exit 1
fi

log "flutter test"
flutter test

if [ "$MODE" = "release" ]; then
  log "flutter build macos --release"
  flutter build macos --release
  SRC="build/macos/Build/Products/Release/$APP_NAME.app"
else
  log "flutter build macos --debug"
  flutter build macos --debug
  SRC="build/macos/Build/Products/Debug/$APP_NAME.app"
fi

rm -rf "$DEST"
cp -R "$SRC" "$DEST"
pkill -f "$APP_NAME" 2>/dev/null || true
sleep 1
open "$DEST"

log "deployed: $DEST"
