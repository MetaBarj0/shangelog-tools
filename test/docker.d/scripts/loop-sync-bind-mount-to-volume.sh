#!/bin/sh

bind_mount='/root/ringover-shangelog-tools/'

while true; do
  entr -addn /root/initial-sync-bind-mount-to-volume.sh 2>/dev/null << EOF
$(find "$bind_mount" -type f)
EOF
done
