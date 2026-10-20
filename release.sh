#!/usr/bin/env bash
# Runs the tests, then builds a downloadable zip of the app plus its checksum for a GitHub Release
# (nothing is installed). Upload both files: install.sh refuses a download without a matching checksum.
set -euo pipefail
cd "$(dirname "$0")"

swift test
INSTALL=0 ./build.sh
VERSION="$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Info.plist)"
ZIP_NAME="ExerciseMoose-$VERSION.zip"
ZIP="build/$ZIP_NAME"
rm -f "$ZIP" "$ZIP.sha256"
ditto -c -k --keepParent "build/Exercise Moose.app" "$ZIP"
(cd build && shasum -a 256 "$ZIP_NAME" > "$ZIP_NAME.sha256")
echo "✓ $ZIP ($(du -h "$ZIP" | cut -f1)) and $ZIP_NAME.sha256"
