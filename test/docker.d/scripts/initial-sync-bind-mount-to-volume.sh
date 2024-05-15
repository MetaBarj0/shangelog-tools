#!/bin/sh

bind_mount='/root/ringover-shangelog-tools/'
volume='/root/ringover-shangelog-volume/'

rsync -a --delete "$bind_mount" "$volume" 2>/dev/null
