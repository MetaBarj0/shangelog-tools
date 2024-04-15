#!/bin/sh

script_dir="$(dirname $0)"
cd "$script_dir" 2>&1 >/dev/null
script_dir="$(pwd)"
cd - 2>&1 >/dev/null

cd "${script_dir}/.." 2>&1 >/dev/null
git submodule --quiet update --init --recursive
cd - 2>&1 >/dev/null

docker build \
  -q \
  -t shangelog-tools-tester \
  "${script_dir}/docker.d" \
  >/dev/null

docker run \
  --rm \
  -it \
  -v "${script_dir}/../":/root/ringover-shangelog-tools/:ro \
  shangelog-tools-tester
