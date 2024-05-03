#!/bin/sh

alias bats=test/bats/bin/bats

bats test/generate

[ ! -z "$1" ] \
  && echo Press any key to continue... \
  && read -n1 -s

unalias bats
