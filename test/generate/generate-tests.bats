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

  source ./generate.sh.d/strings.sh
}

teardown() {
  rm -rf /root/src

  cd /root/ringover-shangelog-tools
}

@test "generate fails with '1' if not run within a git repository" {
  run -1 generate.sh

  assert_output "${generate_error_not_git_repository}"
}

@test "generate fails in a git repository without any commit" {
  create_git_repository

  run -1 generate.sh

  assert_output "${generate_error_no_commits}"
}

@test "generate fails if there is pending changes in the repository" {
  create_git_repository
  commit_with_message 'chore: First conventional chore commit'
  touch pending.txt
  git add pending.txt

  run -1 generate.sh

  assert_output "$generate_error_pending_changes"
}

@test "generate fails if it does not find any conventional commit in the history" {
  create_git_repository
  commit_with_message 'non conventional commit'
  commit_with_message 'chore:'
  commit_with_message 'chore:       too much spaces'
  commit_with_message 'chore(scope):       too much spaces'

  run -1 generate.sh

  assert_output "$generate_error_no_conventional_commit_found"
}

@test "generate succeeds to create several unreleased chore entries change log" {
  create_git_repository
  commit_with_message 'chore: Initial commit'
  commit_with_message 'chore: Second commit'
  commit_with_message 'non conventional commit in the branch'
  commit_with_message 'chore(arbitrary scope): Third commit'

  local expected_output="$(cat << EOF
${generate_changelog_header}

### chore

- Initial commit
- Second commit
- (arbitrary scope) Third commit
EOF
)"

  run generate.sh

  assert_output "$expected_output"
}

@test "generate succeeds to create several unreleased feat entries change log" {
  create_git_repository
  commit_with_message 'feat: Initial commit'
  commit_with_message 'feat(a scope): Second commit'
  commit_with_message 'non conventional commit in the branch'
  commit_with_message 'feat(last scope): Third commit'

  local expected_output="$(cat << EOF
${generate_changelog_header}

### feat

- Initial commit
- (a scope) Second commit
- (last scope) Third commit
EOF
)"

  run generate.sh

  assert_output "$expected_output"
}

@test "generates handles correctly interleaved conventional commit types" {
  create_git_repository
  commit_with_message 'feat: Initial commit'
  commit_with_message 'chore(a chore scope): Second commit, chore one'
  commit_with_message 'non conventional commit in the branch'
  commit_with_message 'feat(last feature): latest fancy feature'
  commit_with_message 'chore(style): reformat, more stylish'

  local expected_output="$(cat << EOF
${generate_changelog_header}

### feat

- Initial commit
- (last feature) latest fancy feature

### chore

- (a chore scope) Second commit, chore one
- (style) reformat, more stylish
EOF
)"

  run generate.sh

  assert_output "$expected_output"
}
