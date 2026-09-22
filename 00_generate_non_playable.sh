#!/usr/bin/env bash
set -euo pipefail

# Create disabled UNO card PNGs by changing only the outer white frame to red.
# Usage: ./00_generate_non_playable.sh [--demo]

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PLAYABLE_DIR="$ROOT_DIR/images/uno/deck/png"
OUTPUT_DIR="$ROOT_DIR/images/uno/deck/png_non_playable"

usage() {
  echo "Usage: $(basename "$0") [--demo]" >&2
}

demo=false
if [[ $# -gt 1 ]]; then
  usage
  exit 2
fi
if [[ $# -eq 1 ]]; then
  if [[ $1 != "--demo" ]]; then
    usage
    exit 2
  fi
  demo=true
fi

command -v python3 >/dev/null || {
  echo "error: python3 with Pillow is required" >&2
  exit 1
}
python3 -c 'from PIL import Image' 2>/dev/null || {
  echo "error: Python Pillow is required (pip install Pillow)" >&2
  exit 1
}

[[ -d $PLAYABLE_DIR ]] || {
  echo "error: playable PNG folder not found: $PLAYABLE_DIR" >&2
  exit 1
}

# Color-picker cards are only used while choosing a color, so they do not need
# a disabled counterpart. This matches the old asset structure.
mapfile -d '' inputs < <(
  find "$PLAYABLE_DIR" -maxdepth 1 -type f -name '*.png' \
    ! -name 'color_red.png' \
    ! -name 'color_blue.png' \
    ! -name 'color_green.png' \
    ! -name 'color_yellow.png' \
    -print0 | sort -z
)

(( ${#inputs[@]} > 0 )) || {
  echo "error: no eligible playable PNG files found in $PLAYABLE_DIR" >&2
  exit 1
}

render_non_playable() {
  local input=$1
  local output=$2

  python3 - "$input" "$output" <<'PY'
from pathlib import Path
import sys

from PIL import Image

source = Path(sys.argv[1])
target = Path(sys.argv[2])
image = Image.open(source).convert("RGBA")
width, height = image.size
pixels = image.load()

# The frame is the only near-white art within the outer edge band. Keeping the
# mask in that band avoids recolouring central values and action symbols, while
# also handling rounded anti-aliased frames whose white pixels are not one
# fully connected component.
near_white = lambda px: px[3] > 0 and px[0] >= 220 and px[1] >= 220 and px[2] >= 220
edge_band = max(24, round(min(width, height) * 0.06))
frame_pixels = {
    (x, y)
    for y in range(height)
    for x in range(width)
    if near_white(pixels[x, y])
    and (x < edge_band or x >= width - edge_band or y < edge_band or y >= height - edge_band)
}

if not frame_pixels:
    raise SystemExit(f"error: could not identify the white card frame in {source}")

for x, y in frame_pixels:
    red, green, blue, alpha = pixels[x, y]
    brightness = max(red, green, blue)
    pixels[x, y] = (brightness, 0, 0, alpha)

target.parent.mkdir(parents=True, exist_ok=True)
image.save(target, format="PNG")
PY
}

if [[ $demo == true ]]; then
  input=${inputs[RANDOM % ${#inputs[@]}]}
  output="$PWD/demo.png"
  render_non_playable "$input" "$output"
  echo "Demo: $(basename "$input") -> $output"
  exit 0
fi

mkdir -p "$OUTPUT_DIR"
for input in "${inputs[@]}"; do
  output="$OUTPUT_DIR/$(basename "$input")"
  render_non_playable "$input" "$output"
  echo "Generated: $input -> $output"
done
