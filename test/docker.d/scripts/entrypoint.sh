#!/bin/sh

alias bats=test/bats/bin/bats

bats test/generate/generate-tests.bats

echo Press any key to continue...
read -n1 -s

unalias bats
