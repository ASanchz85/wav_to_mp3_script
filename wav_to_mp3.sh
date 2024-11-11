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

# Convert .wav files to .mp3 in the specified directory
echo "Converting .wav files in '$target_dir' to .mp3 at 128kbps..."
for file in "$target_dir"/*.wav; do
  if [ -f "$file" ]; then
    ffmpeg -i "$file" -b:a 128k "${file%.wav}.mp3"
    echo "Converted: $file"
  else
    echo "No .wav files found in '$target_dir'."
    break
  fi
done

echo "Conversion complete."
