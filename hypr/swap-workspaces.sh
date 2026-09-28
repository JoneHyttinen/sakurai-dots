#!/usr/bin/env bash

TARGET="$1"

CURRENT=$(hyprctl activeworkspace -j | jq -r '.id')

[ "$CURRENT" = "$TARGET" ] && exit 0

TEMP=99

# Move current workspace windows to temporary workspace
hyprctl clients -j \
| jq -r ".[] | select(.workspace.id == $CURRENT) | .address" \
| while read -r addr; do
    hyprctl dispatch "hl.dsp.window.move({ workspace = \"$TEMP\", window = \"address:$addr\" })"
done

# Move target workspace windows to current workspace
hyprctl clients -j \
| jq -r ".[] | select(.workspace.id == $TARGET) | .address" \
| while read -r addr; do
    hyprctl dispatch "hl.dsp.window.move({ workspace = \"$CURRENT\", window = \"address:$addr\" })"
done

# Move temporary workspace windows to target workspace
hyprctl clients -j \
| jq -r ".[] | select(.workspace.id == $TEMP) | .address" \
| while read -r addr; do
    hyprctl dispatch "hl.dsp.window.move({ workspace = \"$TARGET\", window = \"address:$addr\" })"
done

# Focus target workspace
hyprctl dispatch "hl.dsp.focus({ workspace = \"$TARGET\" })"
