#!/usr/bin/env bash
# Installs Exercise Moose from the latest GitHub release and adds the `moose` terminal command:
#   curl -fsSL https://raw.githubusercontent.com/harpreetkbadhan/exercise-moose/main/install.sh | bash
# Downloads are checked against the release's .sha256 file before anything is installed.
# Testing overrides: MOOSE_ZIP=<local zip, checked against <zip>.sha256 if present>  MOOSE_APP_DIR=<folder>
#                    MOOSE_BIN_DIR=<folder>  MOOSE_NO_OPEN=1
set -euo pipefail

REPO="harpreetkbadhan/exercise-moose"
APP_NAME="Exercise Moose.app"
APP_DIR="${MOOSE_APP_DIR:-/Applications}"
BIN_DIR="${MOOSE_BIN_DIR:-/usr/local/bin}"
MIN_MACOS=14

fail() { echo "✗ $*" >&2; exit 1; }

[ "$(uname)" = "Darwin" ] || fail "Exercise Moose runs on macOS only."
[ "$(sw_vers -productVersion | cut -d. -f1)" -ge "$MIN_MACOS" ] || fail "Exercise Moose needs macOS $MIN_MACOS or later."

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# The download URL of the release file whose name ends in $1 (a grep pattern), or nothing.
asset_url() {
  printf '%s' "$release" | grep -o "\"browser_download_url\": *\"[^\"]*$1\"" | head -1 \
    | sed 's/.*"\(https[^"]*\)"$/\1/' || true
}

# Stops unless the zip ($1) matches the SHA-256 in the checksum file ($2) that release.sh writes.
verify_checksum() {
  local expected actual
  expected="$(awk '{print $1}' "$2")"
  actual="$(shasum -a 256 "$1" | awk '{print $1}')"
  if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
    fail "The download doesn't match its checksum, so nothing was installed. Please try again."
  fi
}

if [ -n "${MOOSE_ZIP:-}" ]; then
  cp "$MOOSE_ZIP" "$tmp/app.zip"
  if [ -f "$MOOSE_ZIP.sha256" ]; then verify_checksum "$tmp/app.zip" "$MOOSE_ZIP.sha256"; fi
else
  release="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest")" \
    || fail "Couldn't find a release to download at github.com/$REPO/releases."
  url="$(asset_url '\.zip')"
  checksum_url="$(asset_url '\.zip\.sha256')"
  [ -n "$url" ] || fail "Couldn't find a release to download at github.com/$REPO/releases."
  [ -n "$checksum_url" ] || fail "The latest release has no checksum file, so it can't be verified."
  echo "Downloading $url"
  curl -fL --progress-bar "$url" -o "$tmp/app.zip"
  curl -fsSL "$checksum_url" -o "$tmp/app.zip.sha256"
  verify_checksum "$tmp/app.zip" "$tmp/app.zip.sha256"
  echo "✓ Checksum verified"
fi

ditto -x -k "$tmp/app.zip" "$tmp/unzipped"
[ -d "$tmp/unzipped/$APP_NAME" ] || fail "The download didn't contain $APP_NAME."

mkdir -p "$APP_DIR" 2>/dev/null || true
if [ ! -w "$APP_DIR" ]; then
  APP_DIR="$HOME/Applications"
  mkdir -p "$APP_DIR"
fi
pkill -x ExerciseMoose 2>/dev/null || true
rm -rf "${APP_DIR:?}/$APP_NAME"
ditto "$tmp/unzipped/$APP_NAME" "$APP_DIR/$APP_NAME"
echo "✓ Installed $APP_DIR/$APP_NAME"

# The terminal command is a symlink to the app's program, which switches to terminal mode under that name.
target="$APP_DIR/$APP_NAME/Contents/MacOS/ExerciseMoose"
if mkdir -p "$BIN_DIR" 2>/dev/null && [ -w "$BIN_DIR" ]; then
  ln -sf "$target" "$BIN_DIR/moose"
else
  echo "Adding the 'moose' command to $BIN_DIR needs your password:"
  sudo mkdir -p "$BIN_DIR"
  sudo ln -sf "$target" "$BIN_DIR/moose"
fi
echo "✓ Terminal command: moose   (try: moose help)"

if [ "${MOOSE_NO_OPEN:-0}" != "1" ]; then
  open "$APP_DIR/$APP_NAME"
  echo "✓ Look for your avatar in the menu bar."
fi
