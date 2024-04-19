#!/bin/env bats

setup_file() {
  bats_require_minimum_version 1.5.0

  PATH=/root/src:${PATH}
}

setup() {
  load '../test_helper/bats-support/load'
  load '../test_helper/bats-assert/load'

  load 'helpers/git_repository_helpers.sh'

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

@test "generate fails in a git repository without any commit" {
  create_git_repository

  run -1 generate.sh

  assert_output 'Error: the git repository does not contain any commit'
}

@test "generate fails if it does not find any conventional commit in the history" {
  create_git_repository
  commit_with_message 'non conventipnal commit'

  run -1 generate.sh

  assert_output 'Error: no suitable commit found to generate the change log'
}

@test "generate fails if there is pending changes in the repository" {
  create_git_repository
  commit_with_message 'chore: First conventional chore commit'
  touch pending.txt
  git add pending.txt
  expected_output="$(cat << EOF
Error: there are pending changes in the repository. Commit, discard or stash
them before going any further.
EOF
)"

  run -1 generate.sh

  assert_output "$expected_output"
}

@test "generate succeeds to create several unreleased chore entries change log" {
  create_git_repository
  commit_with_message 'chore: Initial commit'
  commit_with_message 'chore: Second commit'
  commit_with_message 'non conventional commit in the branch'
  commit_with_message 'chore: Third commit'

  local expected_output="$(cat << EOF
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### chore

- Initial commit
- Second commit
- Third commit
EOF
)"

  run generate.sh

  assert_output "$expected_output"
}
