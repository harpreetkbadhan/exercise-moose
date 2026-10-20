#!/usr/bin/env bash
# Removes the green background from your AI assets so the app can use them:
#   raw/character.png        -> ~/Library/Application Support/Exercise Moose/character.png         (standing still)
#   raw/character-seated.png -> ~/Library/Application Support/Exercise Moose/character-seated.png  (sitting still)
#   raw/squats.mp4           -> ~/Library/Application Support/Exercise Moose/exercises/squats.mov
set -euo pipefail
cd "$(dirname "$0")"
APP_DIR="${APP_DIR:-$HOME/Library/Application Support/Exercise Moose}"  # build.sh overrides this to bundle the sample
OUT_DIR="$APP_DIR/exercises"

# Calibration knob: raise if green edges remain (AI greens are rarely pure), lower if the character gets holes.
SIMILARITY="${SIMILARITY:-0.25}"
BLEND="${BLEND:-0.08}"
KEY="chromakey=0x00FF00:${SIMILARITY}:${BLEND},despill=type=green,scale=600:-2"

mkdir -p "$OUT_DIR"
did_something=false

shopt -s nullglob
for picture in raw/character*.png; do  # the app only uses these; logo and icons in raw/ are not avatar media
  name="$(basename "$picture")"
  ffmpeg -y -loglevel error -i "$picture" -vf "$KEY,format=rgba" -frames:v 1 "$APP_DIR/$name"
  echo "✓ $APP_DIR/$name"
  did_something=true
done

for clip in raw/*.mp4 raw/*.mov; do
  name="$(basename "${clip%.*}")"
  ffmpeg -y -loglevel error -i "$clip" -vf "$KEY,format=bgra" \
    -c:v hevc_videotoolbox -alpha_quality 0.75 -tag:v hvc1 -an "$OUT_DIR/${name}.mov"
  echo "✓ $OUT_DIR/${name}.mov"
  did_something=true
done

if [ "$did_something" = false ]; then
  echo "Nothing found. Put raw/character.png and/or video clips (e.g. raw/squats.mp4) in raw/ and run again."
  exit 1
fi
