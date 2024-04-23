#!/bin/env bats

setup_file() {
  bats_require_minimum_version 1.5.0

  PATH=/root/src:${PATH}
}

setup() {
  load '../test_helper/bats-support/load'
  load '../test_helper/bats-assert/load'

  load 'helpers/git_repository_helpers.sh'
  load 'helpers/ensure_match.sh'
  load 'helpers/patterns.sh'

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

  assert_output "${generate_error_cannot_bind_git_repository}"
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

  local expected_output_pattern="$(cat << EOF
^### chore$

^- \(arbitrary scope\) Third commit ${generate_sha1_pattern}$
^- Second commit ${generate_sha1_pattern}$
^- Initial commit ${generate_sha1_pattern}$
EOF
)"

  run generate.sh

  assert_output --partial "${generate_changelog_header}"
  ensure_match "${output}" "${expected_output_pattern}"
}

@test "generate succeeds to create several unreleased feat entries change log" {
  create_git_repository
  commit_with_message 'feat: Initial commit'
  commit_with_message 'feat(a scope): Second commit'
  commit_with_message 'non conventional commit in the branch'
  commit_with_message 'feat(last scope): Third commit'

  local expected_output_pattern="$(cat << EOF
^### feat$

^- \(last scope\) Third commit ${generate_sha1_pattern}$
^- \(a scope\) Second commit ${generate_sha1_pattern}$
^- Initial commit ${generate_sha1_pattern}$
EOF
)"

  run generate.sh

  assert_output --partial "${generate_changelog_header}"
  ensure_match "${output}" "${expected_output_pattern}"
}

@test "generates handles correctly interleaved conventional commit types" {
  create_git_repository
  commit_with_message 'feat: Initial commit'
  commit_with_message 'chore(a chore scope): Second commit, chore one'
  commit_with_message 'non conventional commit in the branch'
  commit_with_message 'feat(last feature): latest fancy feature'
  commit_with_message 'chore(style): reformat, more stylish'

  run generate.sh

  ensure_match "$output" "^### feat$

^- \(last feature\) latest fancy feature ${generate_sha1_pattern}$
^- Initial commit ${generate_sha1_pattern}$"

  ensure_match "$output" "^### chore$

^- \(style\) reformat, more stylish ${generate_sha1_pattern}$
^- \(a chore scope\) Second commit, chore one ${generate_sha1_pattern}$"
}

@test "generates support all conventional commit type, including Angular convention" {
  create_git_repository
  commit_with_message 'fix: a fix commit'
  commit_with_message 'feat: a feat commit'
  commit_with_message 'build: a build commit'
  commit_with_message 'chore: a chore commit'
  commit_with_message 'ci: a ci commit'
  commit_with_message 'docs: a docs commit'
  commit_with_message 'style: a style commit'
  commit_with_message 'refactor: a refactor commit'
  commit_with_message 'perf: a perf commit'
  commit_with_message 'test: a test commit'

  run generate.sh

  ensure_match "$output" $'### test\n\n- a test commit'
  ensure_match "$output" $'### perf\n\n- a perf commit'
  ensure_match "$output" $'### refactor\n\n- a refactor commit'
  ensure_match "$output" $'### style\n\n- a style commit'
  ensure_match "$output" $'### docs\n\n- a docs commit'
  ensure_match "$output" $'### ci\n\n- a ci commit'
  ensure_match "$output" $'### chore\n\n- a chore commit'
  ensure_match "$output" $'### build\n\n- a build commit'
  ensure_match "$output" $'### feat\n\n- a feat commit'
  ensure_match "$output" $'### fix\n\n- a fix commit'
}

@test "generate must fail if invoked outside of a git repository and the current directory is not a git repository" {
  cd /root

  run -1 ringover-shangelog-tools/src/generate.sh

  assert_output "${generate_error_cannot_bind_git_repository}"
}

@test "generate must succeed when invoked outside a git repository and the current directory is a git repository" {
  mkdir -p inner_git_dir
  cd inner_git_dir
  create_git_repository
  commit_with_message 'chore: a first commit'

  run ../generate.sh

  assert_success
}

@test "generate must succeed when invoked outside a git repository, the current directory is not a git repository and the script argument is a git repository" {
  mkdir -p inner_git_dir
  cd inner_git_dir
  create_git_repository
  commit_with_message 'chore: a first commit'
  cd -

  run generate.sh inner_git_dir

  assert_success
}

@test "generate must show the sha1 of each reported commit" {
  create_git_repository
  commit_with_message 'fix: a fix commit'

  run generate.sh

  ensure_match "$output" "### fix

^- a fix commit ${generate_sha1_pattern}$"
}
