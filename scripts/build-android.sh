#!/bin/bash
set -euo pipefail

APP_NAME="AnywhereTV"
FLUTTER_DIR="$(cd "$(dirname "$0")/../anywhere_tv" && pwd)"
DEST_DIR="$HOME/Applications/apk"

MODE=$1; CLEAN=$2
JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"

log() { echo -e "\033[0;32m[build-android]\033[0m $1"; }
error() { echo -e "\033[0;31m[build-android]\033[0m $1"; }

export JAVA_HOME
[ "$CLEAN" = "true" ] && rm -rf "$FLUTTER_DIR/build"

cd "$FLUTTER_DIR"
if [ "$MODE" = "release" ]; then
  flutter build apk --release
  APK="build/app/outputs/flutter-apk/app-release.apk"
else
  flutter build apk --debug
  APK="build/app/outputs/flutter-apk/app-debug.apk"
fi

if [ ! -f "$APK" ]; then
  error "APK not found"
  exit 1
fi

mkdir -p "$DEST_DIR"
cp "$APK" "$DEST_DIR/$APP_NAME-$MODE.apk"
log "Deployed to $DEST_DIR/$APP_NAME-$MODE.apk"
