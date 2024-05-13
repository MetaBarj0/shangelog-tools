#!/bin/env bats

setup_file() {
  bats_require_minimum_version 1.5.0

}

setup() {
  load '../test_helper/bats-support/load'
  load '../test_helper/bats-assert/load'

  load 'helpers/git_repository_helpers.sh'
  load 'helpers/assert_extra.sh'
  load 'helpers/patterns.sh'
  load 'helpers/tools.sh'

  cp -r src "$BATS_TEST_TMPDIR"
  cd "$BATS_TEST_TMPDIR/src"

  source generate.sh.d/functions.sh
  source generate.sh.d/strings.sh

  PATH="${BATS_TEST_TMPDIR}/src/generate.sh.d:${PATH}"
}

teardown() {
  cd /root/ringover-shangelog-tools
}

@test "A repository without annotated tag generate an unique unreleased changelog section with all conventional commits within" {
  create_git_repository
  commit_with_message 'feat: a great feature'
  commit_with_message 'feat: an extension of the great feature'
  commit_with_message 'feat: another great feature'
  commit_with_message 'a non conventional commit'
  local conventional_commit_count=3
  local type_line_count=2 # ### commit type\n\n

  run generate_sections

  assert_output --partial "## [Unreleased]"
}

@test "A repository with an unique annotated tag generate an unique versioned changelog section with all conventional commits within" {
  create_git_repository
  commit_with_message 'chore: a great reformat'
  commit_with_message 'chore: another style changing'
  commit_with_message 'chore: removing unuseful comment'
  commit_with_message 'a non conventional commit'
  commit_with_message 'chore: a random chore'
  create_annotated_tag v0.1.0
  local conventional_commit_count=4
  local type_line_count=2 # ### commit type\n\n
  local section_line_count=3 # \n## [v0.1.0]\n\n

  run generate_sections

  assert_output --partial "## [v0.1.0]"
  assert_line_count_equals "$output" $(( ${section_line_count} + ${type_line_count} + ${conventional_commit_count} ))
}

@test "A repository with an annotated tag and commits above it generate 2 sections with one being Unreleased, the other being versioned" {
  create_git_repository
  commit_with_message 'chore: a great reformat'
  commit_with_message 'chore: another style changing'
  create_annotated_tag v0.1.0
  commit_with_message 'chore: removing unuseful comment'
  commit_with_message 'a non conventional commit'
  commit_with_message 'chore: a random chore'
  local expected_pattern="^## \[Unreleased\]$

^### chore$

^- a random chore ${generate_sha1_pattern}$
^- removing unuseful comment ${generate_sha1_pattern}$

^## \[v0\.1\.0\]$

^### chore$

^- another style changing ${generate_sha1_pattern}$
^- a great reformat ${generate_sha1_pattern}$"

  run generate_sections

  assert_pcre_match "$output" "${expected_pattern}"
}

@test "A repository with multiple annotated tags output as much as versioned sections" {
  create_git_repository
  commit_with_message 'feat: a great first feature'
  create_annotated_tag v0.1.0
  commit_with_message 'chore: removing unuseful comment'
  create_annotated_tag v0.1.1
  commit_with_message 'a non conventional commit'
  commit_with_message 'refactor: red, green, ...'
  create_annotated_tag v0.1.2
  commit_with_message 'fix: what a mess'
  create_annotated_tag v0.1.3
  local expected_v0_1_3_pattern="^## \[v0\.1\.3\]$

^### fix

^- what a mess ${generate_sha1_pattern}$"
  local expected_v0_1_2_pattern="^## \[v0\.1\.2\]$

^### refactor$

^- red, green, ... ${generate_sha1_pattern}$"
  local expected_v0_1_1_pattern="^## \[v0\.1\.1\]$

^### chore$

^- removing unuseful comment ${generate_sha1_pattern}$"
  local expected_v0_1_0_pattern="^## \[v0\.1\.0\]$

^### feat$

^- a great first feature ${generate_sha1_pattern}$"

  run generate_sections

  assert_pcre_match "$output" "${expected_v0_1_3_pattern}"
  assert_pcre_match "$output" "${expected_v0_1_2_pattern}"
  assert_pcre_match "$output" "${expected_v0_1_1_pattern}"
  assert_pcre_match "$output" "${expected_v0_1_0_pattern}"
}
