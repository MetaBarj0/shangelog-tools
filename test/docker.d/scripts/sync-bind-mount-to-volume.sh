#!/bin/sh

bind_mount='/root/ringover-shangelog-tools/'
volume='/root/ringover-shangelog-volume/'

while true; do
  entr -addn rsync -a --delete "$bind_mount" "$volume" 2>/dev/null << EOF
$(find "$bind_mount" -type f)
EOF
done
