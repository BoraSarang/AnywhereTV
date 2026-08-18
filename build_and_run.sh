#!/bin/bash
set -euo pipefail

APP_NAME="AnywhereTV"
BUNDLE_ID="com.borasarang.anywheretv"

export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
log() { echo -e "${GREEN}[build_and_run]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

MODE="debug"
PLATFORM="auto"
DEVICE=""
DO_CLEAN=false

for arg in "$@"; do
  case $arg in
    debug|release) MODE="$arg" ;;
    macos|ios|android|web|cm|all) PLATFORM="$arg" ;;
    clean) DO_CLEAN=true ;;
    --device=*) DEVICE="${arg#*=}" ;;
    -h|--help)
      echo "Usage: ./build_and_run.sh [debug|release] [macos|ios|android|web|all] [clean] [--device=NAME]"
      echo ""
      echo "Examples:"
      echo "  ./build_and_run.sh                       # macOS debug"
      echo "  ./build_and_run.sh debug macos            # macOS debug"
      echo "  ./build_and_run.sh release android        # Android release"
      echo "  ./build_and_run.sh clean                  # Clean macOS"
      echo "  ./build_and_run.sh clean ios              # Clean iOS"
      exit 0
      ;;
    *) warn "Unknown arg: $arg" ;;
  esac
done

# Platform auto-detection
if [ "$PLATFORM" = "auto" ]; then
  if [ -d "ios" ] || ls *.xcodeproj 2>/dev/null | head -n 1; then PLATFORM="macos"; fi
  if [ -d "android" ]; then PLATFORM="macos"; fi
  if [ -f "package.json" ]; then PLATFORM="macos"; fi
  [ "$PLATFORM" = "auto" ] && PLATFORM="macos"
fi

# Clean-only mode
if [ "$DO_CLEAN" = true ] && [ "$#" -eq 1 ]; then
  log "Clean only"
  rm -rf ./build ./dist ./out
  rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
  log "Clean complete"
  exit 0
fi

run_platform() {
  local p=$1
  local script="scripts/build-$p.sh"
  if [ ! -f "$script" ]; then
    warn "No script: $script, skipping $p"
    return
  fi
  log "▶ $p $MODE build (device: ${DEVICE:-default})"
  bash "$script" "$MODE" "$DO_CLEAN" "$DEVICE"
}

copy_to_dist() {
  local p=$1
  local dist_dir="$(cd "$(dirname "$0")" && pwd)/dist"
  mkdir -p "$dist_dir"
  case "$p" in
    macos)
      ditto "$FLUTTER_DIR/build/macos/Build/Products/Release/AnywhereTV.app" "$dist_dir/AnywhereTV.app" 2>/dev/null || true
      log "Copied macOS release to dist/"
      ;;
    android)
      cp "$FLUTTER_DIR/build/app/outputs/flutter-apk/app-release.apk" "$dist_dir/app-release.apk" 2>/dev/null || true
      log "Copied Android APK to dist/"
      ;;
    ios)
      cp "$FLUTTER_DIR/build/ios/ipa/*.ipa" "$dist_dir/" 2>/dev/null || true
      log "Copied iOS IPA to dist/"
      ;;
    web)
      rm -rf "$dist_dir/web"
      cp -R "$FLUTTER_DIR/build/web" "$dist_dir/web" 2>/dev/null || true
      log "Copied web build to dist/"
      ;;
  esac
}

FLUTTER_DIR="$(cd "$(dirname "$0")/anywhere_tv" && pwd)"

if [ "$PLATFORM" = "cm" ]; then
  CM_DIR="$(cd "$(dirname "$0")/channel_manager" && pwd)"
  if [ ! -f "$CM_DIR/scripts/build-macos.sh" ]; then
    error "No script: $CM_DIR/scripts/build-macos.sh"
    exit 1
  fi
  log "▶ channel_manager $MODE build"
  bash "$CM_DIR/scripts/build-macos.sh" "$MODE"
  log "Done: cm $MODE"
  exit 0
fi

if [ "$PLATFORM" = "all" ]; then
  for p in macos ios android web; do
    run_platform $p
    [ "$MODE" = "release" ] && copy_to_dist $p
  done
else
  run_platform $PLATFORM
  [ "$MODE" = "release" ] && copy_to_dist $PLATFORM
fi

log "Done: $PLATFORM $MODE"
