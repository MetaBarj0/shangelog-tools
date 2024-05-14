#!/bin/sh

initialize_argument_default_values() {
  argument_passed='false'
}

parse_arguments() {
  initialize_argument_default_values

  if [ ! -z "$1" ]; then
    argument_passed='true'
  fi
}

main() {
  local bats=test/bats/bin/bats

  parse_arguments "$@"

  if [ "$argument_passed" = 'false' ]; then
    $bats --formatter tap --jobs $(nproc) test/generate
  elif [ "$argument_passed" = 'true' ]; then
    $bats --formatter tap test/generate
  fi

  local result=$?

  [ ! -z "$1" ] \
    && echo Press any key to continue... \
    && read -n1 -s

  return $result
}

main "$@"
