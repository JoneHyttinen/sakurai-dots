#!/usr/bin/env bash
set -e
THEME="$HOME/.local/share/icons/invisible"
mkdir -p "$THEME/cursors"
TMP="$(mktemp -d)"
cd "$TMP"

# Generate a fully transparent 32x32 PNG using only the Python stdlib
python3 - <<'EOF'
import zlib, struct
def chunk(t, d):
    return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
w = h = 32
raw = b''.join(b'\x00' + b'\x00' * 4 * w for _ in range(h))
png = (b'\x89PNG\r\n\x1a\n'
       + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0))
       + chunk(b'IDAT', zlib.compress(raw))
       + chunk(b'IEND', b''))
open('blank.png', 'wb').write(png)
EOF

echo "32 0 0 blank.png" >blank.cfg
xcursorgen blank.cfg "$THEME/cursors/default"

# Point every common cursor name at the blank one
cd "$THEME/cursors"
for n in left_ptr arrow top_left_arrow pointer hand hand1 hand2 pointing_hand \
  text xterm ibeam vertical-text wait watch progress left_ptr_watch half-busy \
  crosshair cross tcross cell move fleur all-scroll grab grabbing openhand closedhand \
  dnd-move dnd-copy dnd-link dnd-none copy alias no-drop not-allowed forbidden \
  help question_arrow whats_this context-menu zoom-in zoom-out \
  col-resize row-resize ew-resize ns-resize nesw-resize nwse-resize \
  n-resize s-resize e-resize w-resize ne-resize nw-resize se-resize sw-resize \
  sb_h_double_arrow sb_v_double_arrow size_hor size_ver size_bdiag size_fdiag \
  top_side bottom_side left_side right_side \
  top_left_corner top_right_corner bottom_left_corner bottom_right_corner \
  split_h split_v h_double_arrow v_double_arrow pirate X_cursor; do
  ln -sf default "$n"
done

cat >"$THEME/index.theme" <<'EOF'
[Icon Theme]
Name=invisible
Comment=Fully transparent cursor
EOF

echo "Installed to $THEME"
