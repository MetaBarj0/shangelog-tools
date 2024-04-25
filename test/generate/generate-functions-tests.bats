#!/bin/env bats

setup_file() {
  bats_require_minimum_version 1.5.0

  PATH=/root/test/src/generate.sh.d:${PATH}
}

setup() {
  load '../test_helper/bats-support/load'
  load '../test_helper/bats-assert/load'

  load 'helpers/git_repository_helpers.sh'
  load 'helpers/ensure_match.sh'
  load 'helpers/patterns.sh'
  load 'helpers/tools.sh'

  mkdir -p /root/test
  cp -r src /root/test
  cd /root/test/src

  source generate.sh.d/functions.sh
}

teardown() {
  rm -rf /root/test

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
  local unreleased_line_count=3 # \n## [Unreleased]\n\n

  run generate_versioned_sections "$(pwd)"
  local output_line_count=0
  while read out; do
    output_line_count=$(bc << EOF_bc
$output_line_count + 1
EOF_bc
    )
  done << EOF
  $output
EOF

  assert_output --partial "## [Unreleased]"
  assert [ $output_line_count -eq $(( $unreleased_line_count + $type_line_count + $conventional_commit_count )) ]
}
