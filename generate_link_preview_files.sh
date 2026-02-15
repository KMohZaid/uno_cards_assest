#!/bin/bash

# Function to convert WebP images to 500x380 PNGs with white background
# Takes two arguments: input folder and output folder
convert_webp_to_png() {
  local input_folder="$1"
  local output_folder="$2"

  # Create output folder if it doesn't exist
  mkdir -p "$output_folder"

  # Loop through all WebP files in the input folder
  for webp_file in "$input_folder"/*.webp; do
    # Get the base filename without extension
    filename=$(basename "$webp_file" .webp)

    # Construct output path
    output_file="$output_folder/${filename}.png"

    echo "Processing $webp_file -> $output_file"

    # Convert to 500x380 PNG with white background and centered
    magick "$webp_file" \
      -resize 500x380 \
      -background white \
      -gravity center \
      -extent 500x380 \
      -alpha remove \
      -flatten \
      "$output_file"
  done
}

# Only doing this folder as these are sent in chat as stickers,
# but for link preview we are making this image with white background

# Input and output paths
input_path="images/classic_colorblind/webp"
output_path="auto_output/images/classic_colorblind/png"

# Call the function
convert_webp_to_png "$input_path" "$output_path"
