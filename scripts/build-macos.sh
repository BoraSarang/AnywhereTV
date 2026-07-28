#!/bin/bash
set -euo pipefail

APP_NAME="AnywhereTV"
FLUTTER_DIR="$(cd "$(dirname "$0")/../anywhere_tv" && pwd)"
DEST_DIR="$HOME/Applications"

MODE=$1; CLEAN=$2

log() { echo -e "\033[0;32m[build-macos]\033[0m $1"; }
error() { echo -e "\033[0;31m[build-macos]\033[0m $1"; }

pkill -9 "$APP_NAME" 2>/dev/null || true
killall "$APP_NAME" 2>/dev/null || true
osascript -e "tell application \"$APP_NAME\" to quit" 2>/dev/null || true
sleep 1

[ "$CLEAN" = "true" ] && rm -rf "$FLUTTER_DIR/build" ~/Library/Developer/Xcode/DerivedData/*

cd "$FLUTTER_DIR"

if [ "$MODE" = "release" ]; then
  flutter build macos --release
  BUILT_APP=$(find "build/macos/Build/Products/Release" -name "*.app" -maxdepth 1 | head -n 1)
else
  flutter build macos --debug
  BUILT_APP=$(find "build/macos/Build/Products/Debug" -name "*.app" -maxdepth 1 | head -n 1)
fi

if [ -z "$BUILT_APP" ] || [ ! -d "$BUILT_APP" ]; then
  error "Built .app not found"
  exit 1
fi

mkdir -p "$DEST_DIR"
rm -rf "$DEST_DIR/$APP_NAME.app"
ditto "$BUILT_APP" "$DEST_DIR/$APP_NAME.app"
log "Deployed to $DEST_DIR/$APP_NAME.app"

open "$DEST_DIR/$APP_NAME.app"
log "Running $MODE mode"
