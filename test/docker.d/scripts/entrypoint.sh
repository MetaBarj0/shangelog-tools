#!/bin/sh

alias bats=test/bats/bin/bats

bats test/generate

result=$?

[ ! -z "$1" ] \
  && echo Press any key to continue... \
  && read -n1 -s

unalias bats

exit $result
