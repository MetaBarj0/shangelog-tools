#!/bin/sh

get_script_dir() {
  cd "$(dirname $0)" 2>&1 >/dev/null

  echo "$(pwd)"

  cd - 2>&1 >/dev/null
}

clone_bats() {
  cd "$(get_script_dir)/.." 2>&1 >/dev/null
  git submodule --quiet update --init --recursive
  cd - 2>&1 >/dev/null
}

build_tester_image() {
  docker build \
    -q \
    -t shangelog-tools-tester \
    "$(get_script_dir)/docker.d" \
    -f "$(get_script_dir)/docker.d/tester.Dockerfile" \
    >/dev/null
}

build_remote_git_repository_server_image() {
  docker build \
    -q \
    -t shangelog-tools-remote-git-repository-server \
    "$(get_script_dir)/docker.d" \
    -f "$(get_script_dir)/docker.d/remote-git-repository-server.Dockerfile" \
    >/dev/null
}

start_remote_git_repository_server() {
  # TODO: remove -it flags as soon as it works
  docker run \
    --init --rm -d -it \
    --name shangelog-tools-remote-git-repository-server \
    --network=host \
    shangelog-tools-remote-git-repository-server \
    >/dev/null
}

prepare_test_environment() {
  echo 'preparing test environment...'

  clone_bats \
  && build_tester_image \
  && build_remote_git_repository_server_image \
  && start_remote_git_repository_server
}

run_test_suites() {
  echo 'running tests...'

  # https://bats-core.readthedocs.io/en/stable/writing-tests.html#special-variables
  # for explanation about $BATS_TMPDIR and /tmp
  docker run \
    --init --rm -it \
    --network=host \
    -e TMPDIR=/tmp \
    -e HOST_TESTER_OUTPUT_DIR="$(get_script_dir)/tester_bind_mount/output" \
    -e HOST_TESTER_SSH_DIR="$(get_script_dir)/tester_bind_mount/.ssh" \
    -v "$(get_script_dir)/../":/root/ringover-shangelog-tools/:ro \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    -v "$(get_script_dir)/tester_bind_mount/output":/tmp \
    -v "$(get_script_dir)/tester_bind_mount/.ssh":/root/.ssh \
    shangelog-tools-tester "$@"
}

cleanup() {
  echo 'cleaning up the mess...'

  docker stop shangelog-tools-remote-git-repository-server >/dev/null
  docker image rm shangelog-tools-tester >/dev/null
  docker image rm shangelog-tools-remote-git-repository-server >/dev/null
  git clean -dfx "$(get_script_dir)/tester_bind_mount" >/dev/null
}

main() {
  prepare_test_environment \
  && run_test_suites "$@" \
  ; local result=$? \
  && cleanup

  return $result
}

main "$@"
