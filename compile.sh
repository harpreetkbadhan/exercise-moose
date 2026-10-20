#!/usr/bin/env bash
# Compiles the app's program as a universal binary (Apple silicon + Intel) for the macOS version in Info.plist:
#   ./compile.sh <output path, relative to this folder>    (used by build.sh and CI)
set -euo pipefail
cd "$(dirname "$0")"

[ $# -eq 1 ] || { echo "usage: ./compile.sh <output>" >&2; exit 2; }
OUTPUT="$1"
# Without an explicit target, swiftc builds only for this Mac's CPU and this Mac's macOS version.
MIN_MACOS="$(/usr/libexec/PlistBuddy -c "Print LSMinimumSystemVersion" Info.plist)"
ARCHS=(arm64 x86_64)

slices="$(mktemp -d)"
trap 'rm -rf "$slices"' EXIT
for arch in "${ARCHS[@]}"; do
  swiftc -O -target "$arch-apple-macos$MIN_MACOS" Sources/ExerciseMoose/*.swift -o "$slices/$arch"
done
lipo -create "${ARCHS[@]/#/$slices/}" -output "$OUTPUT"
