#!/bin/sh

alias bats=test/bats/bin/bats

if [ -z "$1" ]; then
  bats --formatter tap --jobs $(nproc) test/generate
else
  bats --formatter tap test/generate
fi

result=$?

[ ! -z "$1" ] \
  && echo Press any key to continue... \
  && read -n1 -s

unalias bats

exit $result
