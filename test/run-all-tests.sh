#!/bin/sh

script_dir="$(dirname $0)"
cd "$script_dir" 2>&1 >/dev/null
script_dir="$(pwd)"
cd - 2>&1 >/dev/null

echo 'Cloning bats submodules...'
cd "${script_dir}/.." 2>&1 >/dev/null
git submodule --quiet update --init --recursive
cd - 2>&1 >/dev/null

echo 'Building docker test image...'
docker build \
  -q \
  -t shangelog-tools-tester \
  "${script_dir}/docker.d" \
  >/dev/null

echo 'Running tests...'
docker run \
  --init --rm -it \
  -v "${script_dir}/../":/root/ringover-shangelog-tools/:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  shangelog-tools-tester "$@"

result=$?

echo 'Cleaning up the mess...'
docker image rm shangelog-tools-tester >/dev/null

exit $result
