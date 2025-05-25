#!/bin/bash

# Usage function
usage() {
  echo "Usage: $0 -d <directory>"
  echo "  -d: Directory containing .wav files (use '.' for current directory)"
  exit 1
}

# Parse arguments
while getopts "d:" opt; do
  case $opt in
  d) directory="$OPTARG" ;;
  *) usage ;;
  esac
done

# Check if directory argument was provided
if [ -z "$directory" ]; then
  usage
fi

# Navigate to the specified directory
if [ "$directory" == "." ]; then
  target_dir=$(pwd)
else
  target_dir="$directory"
fi

# Check if target directory exists
if [ ! -d "$target_dir" ]; then
  echo "Error: Directory '$target_dir' does not exist."
  exit 1
fi

# Define output base directory
output_base="$target_dir/mp3"
mkdir -p "$output_base"

# Find and convert .wav files recursively
echo "Converting .wav files in '$target_dir' to .mp3 at 128kbps..."
found_files=false

while IFS= read -r -d '' wav_file; do
  found_files=true
  # Get relative path from base dir and determine new output path
  relative_path="${wav_file#$target_dir/}"
  output_path="$output_base/${relative_path%.wav}.mp3"
  output_dir=$(dirname "$output_path")

  mkdir -p "$output_dir"
  ffmpeg -nostdin -hide_banner -loglevel error -i "$wav_file" -b:a 128k "$output_path"
  echo "Converted: $wav_file -> $output_path"
done < <(find "$target_dir" -type f -name "*.wav" -print0)

if ! $found_files; then
  echo "No .wav files found in '$target_dir'."
fi

echo "Conversion complete."
