#!/bin/sh

alias bats=test/bats/bin/bats

bats test/generate

echo Press any key to continue...

[ ! -z "$1" ] && read -n1 -s

unalias bats
