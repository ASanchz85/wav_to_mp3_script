#!/bin/bash

# Usage info
usage() {
  echo "Usage: $0 -d <directory> [-c <bitrate>] [-p]"
  echo "  -d: Directory containing .wav files (use '.' for current directory)"
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

echo "Converting .wav files in '$target_dir' to .mp3 at bitrate: $bitrate"
$parallel && echo "Parallel mode enabled."

# Determine CPU cores
max_jobs=$(nproc 2>/dev/null || echo 4)
active_jobs=0
found_files=false

# Conversion function
convert_wav_to_mp3() {
  local wav_file="$1"
  local mp3_file="$2"
  mkdir -p "$(dirname "$mp3_file")"
  ffmpeg -nostdin -hide_banner -loglevel error -i "$wav_file" -b:a "$bitrate" "$mp3_file" 2>/dev/null
}

# Iterate over files
while IFS= read -r -d '' wav_file; do
  found_files=true
  relative_path="${wav_file#$target_dir/}"
  output_path="$output_base/${relative_path%.wav}.mp3"

  echo "Converting: $relative_path"

  if $parallel; then
    convert_wav_to_mp3 "$wav_file" "$output_path" &
    ((active_jobs++))
    if [ "$active_jobs" -ge "$max_jobs" ]; then
      wait -n
      ((active_jobs--))
    fi
  else
    convert_wav_to_mp3 "$wav_file" "$output_path"
  fi

done < <(find "$target_dir" -type f -name "*.wav" -print0)

$parallel && wait

if ! $found_files; then
  echo "No .wav files found in '$target_dir'."
fi

echo "✅ Conversion complete."
