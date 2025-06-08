#!/bin/bash

# Usage info
usage() {
  echo "Usage: $0 -d <directory> [-c <bitrate>] [-p]"
  echo "  -d: Directory containing .wav and .mp3 files (use '.' for current directory)"
  echo "  -c: Target bitrate (default: 128k), e.g., 128k, 192k, 320k"
  echo "  -p: Enable parallel conversion"
  exit 1
}

# Default values
bitrate="128k"
parallel=false

# Parse arguments
while getopts "d:c:p" opt; do
  case $opt in
  d) directory="$OPTARG" ;;
  c) bitrate="$OPTARG" ;;
  p) parallel=true ;;
  *) usage ;;
  esac
done

# Validate directory
if [ -z "$directory" ]; then usage; fi
target_dir=$(realpath "$directory")
[ ! -d "$target_dir" ] && echo "Error: Directory '$target_dir' does not exist." && exit 1

output_base="$target_dir/mp3"
mkdir -p "$output_base"

echo "Converting .wav and reprocessing .mp3 files in '$target_dir' to bitrate: $bitrate"
$parallel && echo "Parallel mode enabled."

max_jobs=$(nproc 2>/dev/null || echo 4)
active_jobs=0
found_files=false

# Conversion function
convert_to_target_mp3() {
  local input_file="$1"
  local output_file="$2"
  mkdir -p "$(dirname "$output_file")"
  ffmpeg -nostdin -hide_banner -loglevel error -i "$input_file" -b:a "$bitrate" "$output_file" 2>/dev/null
}

# Bitrate checker function
get_bitrate() {
  ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate \
    -of default=noprint_wrappers=1:nokey=1 "$1" 2>/dev/null
}

# Normalize target bitrate to bits for comparison
target_bitrate_bits=$(( ${bitrate%k} * 1000 ))

process_file() {
  local file="$1"
  local extension="${file##*.}"
  local relative_path="${file#$target_dir/}"
  local output_path="$output_base/${relative_path%.*}.mp3"

  echo "Processing: $relative_path"

  if [[ "$extension" == "wav" ]]; then
    convert_to_target_mp3 "$file" "$output_path"
  elif [[ "$extension" == "mp3" ]]; then
    current_bitrate=$(get_bitrate "$file")
    if [[ "$current_bitrate" -eq "$target_bitrate_bits" ]]; then
      mkdir -p "$(dirname "$output_path")"
      cp "$file" "$output_path"
      echo "Copied (bitrate matched): $relative_path"
    else
      convert_to_target_mp3 "$file" "$output_path"
      echo "Recompressed (bitrate mismatch): $relative_path"
    fi
  fi
}

# Find and process .wav and .mp3 files
while IFS= read -r -d '' file; do
  found_files=true

  if $parallel; then
    process_file "$file" &
    ((active_jobs++))
    if [ "$active_jobs" -ge "$max_jobs" ]; then
      wait -n
      ((active_jobs--))
    fi
  else
    process_file "$file"
  fi

done < <(find "$target_dir" -type f \( -iname "*.wav" -o -iname "*.mp3" \) -print0)

$parallel && wait

if ! $found_files; then
  echo "No .wav or .mp3 files found in '$target_dir'."
fi

echo "✅ Processing complete."
