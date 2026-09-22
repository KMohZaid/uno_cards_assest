#!/usr/bin/env bash
set -euo pipefail

# Convert playable and disabled UNO PNG assets to high-quality WebP.
# Usage: ./01_png_assests_to_webp.sh [--demo]

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PLAYABLE_PNG_DIR="$ROOT_DIR/images/uno/deck/png"
DISABLED_PNG_DIR="$ROOT_DIR/images/uno/deck/png_non_playable"
PLAYABLE_WEBP_DIR="$ROOT_DIR/images/uno/deck/webp"
DISABLED_WEBP_DIR="$ROOT_DIR/images/uno/deck/webp_non_playable"

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

command -v ffmpeg >/dev/null || {
  echo "error: ffmpeg is required" >&2
  exit 1
}

convert_png() {
  local input=$1
  local output=$2
  # High-quality lossy WebP keeps alpha while avoiding the impractically slow
  # per-file lossless encoding that a full deck would otherwise require.
  ffmpeg -v error -y -i "$input" -c:v libwebp -q:v 90 -compression_level 4 "$output"
}

collect_pngs() {
  local directory=$1
  [[ -d $directory ]] || return 0
  find "$directory" -maxdepth 1 -type f -name '*.png' -print0 | sort -z
}

mapfile -d '' playable_inputs < <(collect_pngs "$PLAYABLE_PNG_DIR")
mapfile -d '' disabled_inputs < <(collect_pngs "$DISABLED_PNG_DIR")
all_inputs=("${playable_inputs[@]}" "${disabled_inputs[@]}")

(( ${#all_inputs[@]} > 0 )) || {
  echo "error: no PNG assets found in $PLAYABLE_PNG_DIR or $DISABLED_PNG_DIR" >&2
  exit 1
}

if [[ $demo == true ]]; then
  input=${all_inputs[RANDOM % ${#all_inputs[@]}]}
  output="$PWD/demo.webp"
  convert_png "$input" "$output"
  echo "Demo: $(basename "$input") -> $output"
  exit 0
fi

convert_folder() {
  local input_dir=$1
  local output_dir=$2
  local -n inputs=$3

  (( ${#inputs[@]} > 0 )) || return 0
  mkdir -p "$output_dir"
  for input in "${inputs[@]}"; do
    output="$output_dir/$(basename "${input%.png}").webp"
    convert_png "$input" "$output"
    echo "Converted: $input -> $output"
  done
}

convert_folder "$PLAYABLE_PNG_DIR" "$PLAYABLE_WEBP_DIR" playable_inputs
convert_folder "$DISABLED_PNG_DIR" "$DISABLED_WEBP_DIR" disabled_inputs
