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

create_non_conventional_commit() {
  git add generate.sh
  git commit -m 'non conventional commit'
}

@test "generate fails if it does not find any conventional commit in the history" {
  create_git_repository
  create_non_conventional_commit

  run -1 generate.sh

  assert_output 'Error: no suitable commit found to generate the change log'
}

teardown() {
  rm -rf /root/src

  cd /root/ringover-shangelog-tools
}
