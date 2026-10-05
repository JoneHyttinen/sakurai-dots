#!/usr/bin/env bash
STATE_FILE="/tmp/hypr_cursor_hidden"
REAL_THEME="Bibata-Modern-Classic" # your normal theme
REAL_SIZE=24

if [ -f "$STATE_FILE" ]; then
  hyprctl setcursor "$REAL_THEME" "$REAL_SIZE"
  rm "$STATE_FILE"
else
  hyprctl setcursor invisible 24
  touch "$STATE_FILE"
fi
