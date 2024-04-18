#!/bin/env bats

setup_file() {
  bats_require_minimum_version 1.5.0

  PATH=/root/src:${PATH}
}

setup() {
  load '../test_helper/bats-support/load'
  load '../test_helper/bats-assert/load'

  cp -r src /root
  cd /root/src
}

teardown() {
  rm -rf /root/src

  cd /root/ringover-shangelog-tools
}

@test "generate fails with '1' if not run within a git repository" {
  run -1 generate.sh

  assert_output 'Error: this script must be run within a git repository'
}

create_git_repository() {
  git init > /dev/null 2>&1

  git config user.email "bats@test.suite"
  git config user.name "bats"
}

@test "generate fails in a git repository without any commit" {
  create_git_repository

  run -1 generate.sh

  assert_output 'Error: the git repository does not contain any commit'
}

commit_with_message() {
  local message="$1"

  touch messages
  echo "$message" >> messages
  git add messages
  git commit -m "$message"
}

@test "generate fails if it does not find any conventional commit in the history" {
  create_git_repository
  commit_with_message 'non conventipnal commit'

  run -1 generate.sh

  assert_output 'Error: no suitable commit found to generate the change log'
}

@test "generate succeeds in create a one unreleased entry change log" {
  create_git_repository
  commit_with_message "$(cat << EOF
chore: Initial commit
EOF
)"
  local expected_output="$(cat << EOF
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### chore

- Initial commit
EOF
)"
  commit_with_message 'non conventional commit at the tip of the branch'

  run generate.sh

  assert_output "$expected_output"
}
