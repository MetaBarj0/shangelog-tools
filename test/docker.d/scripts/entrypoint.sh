#!/bin/sh

initialize_argument_default_values() {
  argument_debug='false'
}

show_help() {
  cat << EOF
usage: entrypoint.sh [-h | --help] ([-d | --debug] | [-w | --watch])

Run all test suites either once, or continuously as soon as a file covered by
any test changed.

Options:

  -h  --help

      Display this message.

  -d  --debug

      Run test suites in debug mode. Disable parallel execution of tests and
      allow each test to be paused using the 'pause_test' function. Each paused
      test will display its current directory of execution.
      This implies '-w' or '--watch' is not set.

  -w  --watch

      Run test suites continuously. Each modification on file tracked by a test
      will trigger the execution. To stop the watching process, press CTRL-C.
      This implies '-d' or '--debug' is not set.
EOF
}

parse_arguments() {
  initialize_argument_default_values

  local valid_args \
  && valid_args="$(getopt -q -o hdw --long help,debug,watch -- $@)"

  if [ $? -ne 0 ]; then
    show_help
  fi

  eval set -- "$valid_args"

  while true; do
    case "$1" in
      -d | --debug)
        argument_debug='true'
        argument_watch='false'
        shift
        ;;
      -w | --watch)
        argument_debug='false'
        argument_watch='true'
        shift
        ;;
      -h | --help)
        show_help
        shift
        break
        ;;
      --)
        shift
        break
        ;;
    esac
  done
}

bats() {
  echo test/bats/bin/bats
}

run_test_suites_parallel() {
  $(bats) --formatter tap --jobs $(nproc) test/generate
}

run_test_suites_serial() {
  $(bats) --formatter tap test/generate \
  && echo Press any key to continue... \
  && read -n1 -s
}

watch_and_run_test_suites_parallel() {
  while true; do
    entr -acddn ../watch-and-run-test-suites-in-parallel.sh 2>/dev/null << EOF
$(find src -type f -name *.sh)
$(find test -type f -name '*.bats')
$(find test -type f -name '*.sh')
EOF
  done
}

main() {
  parse_arguments "$@"

  /root/sync-bind-mount-to-volume.sh &

  if [ "$argument_debug" = 'false' ]; then
    if [ "$argument_watch" = 'true' ]; then
      watch_and_run_test_suites_parallel
    else
      run_test_suites_parallel
    fi
  elif [ "$argument_debug" = 'true' ]; then
    run_test_suites_serial
  fi

  local result=$?

  return $result
}

main "$@"
