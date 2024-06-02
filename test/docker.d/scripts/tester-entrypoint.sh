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

generate_client_keys() {
  ssh-keygen -t rsa -q -N 'passphrase' -f /root/.ssh/id_rsa
}

wait_for_ssh_server_readiness() {
  while ! ssh-keyscan \
    -t rsa \
    localhost \
    2>/dev/null 1>&2; do
    sleep 1
  done
}

authorize_public_key_on_server() {
  docker cp \
    /root/.ssh/id_rsa.pub \
    shangelog-tools-remote-git-repository-server:/home/git/.ssh/authorized_keys \
    >/dev/null

  docker exec \
    shangelog-tools-remote-git-repository-server \
    chown git:git /home/git/.ssh/authorized_keys \
    >/dev/null
}

start_ssh_agent() {
  eval "$(ssh-agent -a /root/.ssh/agent-sock)" > /dev/null

  expect >/dev/null << EOF
spawn ssh-add /root/.ssh/id_rsa
expect "Enter passphrase"
send "passphrase\r"
expect eof
EOF
}

setup_ssh_client() {
  generate_client_keys \
  && wait_for_ssh_server_readiness \
  && authorize_public_key_on_server \
  && start_ssh_agent
}

setup_git_test_user_info_for_repository() {
  git config --global user.email "bats@test.suite"
  git config --global user.name "bats"
}

run() {
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

main() {
  parse_arguments "$@" \
  && setup_git_test_user_info_for_repository \
  && setup_ssh_client \
  && run
}

main "$@"
