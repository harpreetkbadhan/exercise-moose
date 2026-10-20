#!/usr/bin/env bash
# Builds "Exercise Moose.app" and installs it into /Applications.
# INSTALL=0 ./build.sh only builds (used by release.sh).
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="Exercise Moose.app"
BUILD_APP="build/$APP_NAME"
BINARY="$BUILD_APP/Contents/MacOS/ExerciseMoose"
INSTALLED_APP="/Applications/$APP_NAME"
INSTALL="${INSTALL:-1}"

rm -rf "$BUILD_APP"
mkdir -p "$BUILD_APP/Contents/MacOS" "$BUILD_APP/Contents/Resources"
./compile.sh "$BINARY"  # tests: `swift test` (release.sh and CI run them)
cp Info.plist "$BUILD_APP/Contents/"

# Bundle the sample avatar from raw/ so a downloaded app works before you add your own.
APP_DIR="$BUILD_APP/Contents/Resources/Sample" ./convert.sh >/dev/null
echo "✓ Bundled sample avatar"

# Menu bar icon: raw/menubar-icon.png (black silhouette) if present, else the app draws your face.
if [ -f raw/menubar-icon.png ]; then cp raw/menubar-icon.png "$BUILD_APP/Contents/Resources/MenuBarIcon.png"; fi

# App icon: raw/app-icon.png if present, else drawn from your character (or the bundled sample).
ICONSET="build/AppIcon.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
if { [ -f raw/app-icon.png ] && sips -z 1024 1024 raw/app-icon.png --out build/icon_1024.png >/dev/null; } \
   || "$BINARY" --make-icon build/icon_1024.png; then
  for size in 16 32 128 256 512; do
    sips -z "$size" "$size" build/icon_1024.png --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    sips -z $((size * 2)) $((size * 2)) build/icon_1024.png --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
  done
  iconutil -c icns "$ICONSET" -o "$BUILD_APP/Contents/Resources/AppIcon.icns"
else
  echo "No character picture found, building without an app icon."
fi
codesign --force --sign - "$BUILD_APP"
echo "✓ Built $BUILD_APP"

if [ "$INSTALL" = "1" ]; then
  pkill -x ExerciseMoose || true
  rm -rf "$INSTALLED_APP"
  cp -R "$BUILD_APP" /Applications/
  touch "$INSTALLED_APP"  # nudges Finder to refresh the icon
  echo "✓ Installed $INSTALLED_APP"
  echo "  Start it: open \"$INSTALLED_APP\""
fi
