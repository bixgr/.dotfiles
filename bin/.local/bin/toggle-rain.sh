#!/bin/bash
if pgrep -f "mpv.*rain.flac" >/dev/null; then
  pkill -f "mpv.*rain.flac"
else
  nohup /opt/homebrew/bin/mpv --no-video --loop-file=inf --volume=60 \
    "$HOME/Documents/Audacity4/bangkok_rain.flac" >/dev/null 2>&1 &
fi