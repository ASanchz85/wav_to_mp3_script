#!/bin/bash

# Usage info
usage() {
  echo "Usage: $0 -d <directory> [-c <resolution>] [-e] [-p]"
  echo "  -d: Directory containing .mp4 files (use '.' for current directory)"
  echo "  -c: Target resolution (default: 720), values: 1080, 720, 480, etc."
  echo "  -e: Enable extra compression using HEVC (H.265)"
  echo "  -p: Enable parallel compression"
  exit 1
}

# Defaults
resolution=720
extra_compression=false
parallel=false

# Parse arguments
while getopts "d:c:ep" opt; do
  case $opt in
  d) directory="$OPTARG" ;;
  c) resolution="$OPTARG" ;;
  e) extra_compression=true ;;
  p) parallel=true ;;
  *) usage ;;
  esac
done

# Check for directory
if [ -z "$directory" ]; then usage; fi

# Resolve full path
target_dir=$(realpath "$directory")

if [ ! -d "$target_dir" ]; then
  echo "Error: Directory '$target_dir' does not exist."
  exit 1
fi

output_base="$target_dir/compressed_mp4"
mkdir -p "$output_base"

# Choose codec + CRF
if $extra_compression; then
  video_codec="libx265"
  codec_name="HEVC (H.265)"
  crf_value=28
else
  video_codec="libx264"
  codec_name="H.264"
  crf_value=23
fi

echo "Compressing .mp4 files in '$target_dir' to ${resolution}p using $codec_name..."
echo "Output will be in: compressed_mp4/"

# Limit number of parallel jobs
max_jobs=$(nproc 2>/dev/null || echo 4)

run_ffmpeg() {
  local input_file="$1"
  local output_file="$2"

  mkdir -p "$(dirname "$output_file")"

  ffmpeg -nostdin -hide_banner -loglevel error \
    -i "$input_file" \
    -vf "scale=-2:$resolution" \
    -c:v "$video_codec" -preset slow -crf "$crf_value" \
    -c:a aac -b:a 128k \
    "$output_file" 2>/dev/null
}

active_jobs=0
found_files=false

while IFS= read -r -d '' mp4_file; do
  found_files=true
  relative_path="${mp4_file#$target_dir/}"
  output_path="$output_base/${relative_path%.mp4}.mp4"

  echo "Compressing: $relative_path"

  if $parallel; then
    run_ffmpeg "$mp4_file" "$output_path" &

    ((active_jobs++))
    if [ "$active_jobs" -ge "$max_jobs" ]; then
      wait -n
      ((active_jobs--))
    fi
  else
    run_ffmpeg "$mp4_file" "$output_path"
  fi

done < <(find "$target_dir" -type f -name "*.mp4" -print0)

if $parallel; then
  wait  # wait for all background jobs to finish
fi

if ! $found_files; then
  echo "No .mp4 files found in '$target_dir'."
fi

echo "✅ Compression complete."
