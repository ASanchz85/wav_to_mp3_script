# WAV TO MP3 Bash-Tool

This is a simple script to automate turning .wav files into .mp3 ones. The script uses the binary ffmpeg, so be aware of having it installed in your machine.

The quality is set by default to 128kb (cd quality).

## How to install ffmpeg - dependency

```sh
sudo apt update
sudo apt install ffmpeg
```

*if you want to simple execute it for a single file you can type:*

```sh
ffmpeg -i input.wav -b:a 128k output.mp3
```

## How to execute it

First, give it permissions

```sh
chmod +x wav_to_mp3.sh
```

Secondly, choose between executing within the current folder or point out other one.

```sh
./wav_to_mp3.sh -d /path/to/your/directory
./wav_to_mp3.sh -d .
```

## Other options/flags

-d: Directory containing .wav and .mp3 files (use '.' for current directory)"
-c: Target bitrate (default: 128k), e.g., 128k, 192k, 320k"
-p: Enable parallel conversion"
