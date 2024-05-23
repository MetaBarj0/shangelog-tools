#!/bin/sh

get_script_dir() {
  cd "$(dirname $0)" 2>&1 >/dev/null

  echo "$(pwd)"

  cd - 2>&1 >/dev/null
}

prepare_test_environment() {
  echo 'preparing test environment...'

  cd "$(get_script_dir)/.." 2>&1 >/dev/null
  git submodule --quiet update --init --recursive
  cd - 2>&1 >/dev/null

  docker build \
    -q \
    -t shangelog-tools-tester \
    "$(get_script_dir)/docker.d" \
    >/dev/null
}

run_test_suites() {
  echo 'running tests...'

  # https://bats-core.readthedocs.io/en/stable/writing-tests.html#special-variables
  # for explanation about $BATS_TMPDIR and /tmp
  docker run \
    --init --rm -it \
    -e TMPDIR=/tmp \
    -e HOST_TEST_OUTPUT_DIR="$(get_script_dir)/test_output" \
    -v "$(get_script_dir)/../":/root/ringover-shangelog-tools/:ro \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    -v "$(get_script_dir)/test_output":/tmp \
    shangelog-tools-tester "$@"
}

cleanup() {
  echo 'cleaning up the mess...'

  docker image rm shangelog-tools-tester >/dev/null
  rm -rf "$(get_script_dir)/test_output/"*
}

main() {
  prepare_test_environment \
  && run_test_suites "$@" \
  ; local result=$? \
  && cleanup

  return $result
}

main "$@"
