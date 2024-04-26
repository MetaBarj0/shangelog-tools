#!/bin/env bats

setup_file() {
  bats_require_minimum_version 1.5.0

  PATH=/root/test/src:${PATH}
}

setup() {
  load '../test_helper/bats-support/load'
  load '../test_helper/bats-assert/load'

  load 'helpers/git_repository_helpers.sh'
  load 'helpers/assert_extra.sh'
  load 'helpers/patterns.sh'
  load 'helpers/tools.sh'

  mkdir -p /root/test
  cp -r src /root/test
  cd /root/test/src

  source ./generate.sh.d/strings.sh
}

teardown() {
  rm -rf /root/test

  cd /root/ringover-shangelog-tools
}

@test "generate fails with '1' if not targeting git repository" {
  run -1 generate.sh

  assert_output "${generate_error_cannot_bind_git_repository}"
}

@test "generate fails if the git repository does not have any commit" {
  create_git_repository

  run -1 generate.sh

  assert_output "${generate_error_no_commits}"
}

@test "generate fails if there is pending changes in the targeted repository" {
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

  local expected_output_pattern="^## \[Unreleased\]$

^### chore$

^- \(arbitrary scope\) Third commit ${generate_sha1_pattern}$
^- Second commit ${generate_sha1_pattern}$
^- Initial commit ${generate_sha1_pattern}$"

  run generate.sh

  assert_output --partial "${generate_changelog_header}"
  assert_pcre_match "${output}" "${expected_output_pattern}"
}

@test "generate succeeds to create several unreleased feat entries change log" {
  create_git_repository
  commit_with_message 'feat: Initial commit'
  commit_with_message 'feat(a scope): Second commit'
  commit_with_message 'non conventional commit in the branch'
  commit_with_message 'feat(last scope): Third commit'

  local expected_output_pattern="^## \[Unreleased\]$

^### feat$

^- \(last scope\) Third commit ${generate_sha1_pattern}$
^- \(a scope\) Second commit ${generate_sha1_pattern}$
^- Initial commit ${generate_sha1_pattern}$"

  run generate.sh

  assert_output --partial "${generate_changelog_header}"
  assert_pcre_match "${output}" "${expected_output_pattern}"
}

@test "generates handles correctly interleaved conventional commit types" {
  create_git_repository
  commit_with_message 'feat: Initial commit'
  commit_with_message 'chore(a chore scope): Second commit, chore one'
  commit_with_message 'non conventional commit in the branch'
  commit_with_message 'feat(last feature): latest fancy feature'
  commit_with_message 'chore(style): reformat, more stylish'

  run generate.sh

  assert_output --partial "${generate_changelog_header}"
  assert_pcre_match "$output" "^## \[Unreleased\]$

^### feat$

^- \(last feature\) latest fancy feature ${generate_sha1_pattern}$
^- Initial commit ${generate_sha1_pattern}$"

  assert_pcre_match "$output" "^### chore$

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
  commit_with_message 'revert: a revert commit'

  run generate.sh

  assert_output --partial "${generate_changelog_header}"
  assert_output --partial "## [Unreleased]"
  assert_pcre_match "$output" $'### revert\n\n- a revert commit'
  assert_pcre_match "$output" $'### test\n\n- a test commit'
  assert_pcre_match "$output" $'### perf\n\n- a perf commit'
  assert_pcre_match "$output" $'### refactor\n\n- a refactor commit'
  assert_pcre_match "$output" $'### style\n\n- a style commit'
  assert_pcre_match "$output" $'### docs\n\n- a docs commit'
  assert_pcre_match "$output" $'### ci\n\n- a ci commit'
  assert_pcre_match "$output" $'### chore\n\n- a chore commit'
  assert_pcre_match "$output" $'### build\n\n- a build commit'
  assert_pcre_match "$output" $'### feat\n\n- a feat commit'
  assert_pcre_match "$output" $'### fix\n\n- a fix commit'
}

@test "generate must fail if invoked outside of a git repository and the current directory is not a git repository and there is no argument specified" {
  cd /root

  run -1 /root/test/src/generate.sh /

  assert_output "${generate_error_cannot_bind_git_repository}"
}

@test "generate must succeed when invoked outside of a git repository, the current directory is not a git repository and the argument targets a git repository" {
  create_git_repository_and_cd_in ../inner_git_dir
  commit_with_message 'chore: a first commit'
  cd -

  run generate.sh -r ../inner_git_dir

  assert_success
}

@test "generate must succeed when outside of a git repository, the current directory is a git repository, with no argument specified" {
  create_git_repository_and_cd_in ../inner_git_dir
  commit_with_message 'chore: a first commit'

  run ../src/generate.sh

  assert_success
}

@test "generate must succeed when outside of a git repository, the current directory being a git repository and an argument target a git repository. The argument takes precedence" {
  create_git_repository_and_cd_in ../other_git_dir
  commit_with_message 'test: the argument git repository'
  create_git_repository_and_cd_in ../yet_another_git_dir
  commit_with_message 'test: the current directory git repository'

  run ../src/generate.sh -r ../other_git_dir

  assert_pcre_match "$output" $'# test\n\n^- the argument git repository '"${generate_sha1_pattern}"'$'
}

@test "generate must succeed when within a git repository, the current directory is not a git repository and there is no argument specified" {
  create_git_repository
  commit_with_message 'fix: a fix commit'
  cd ..

  run src/generate.sh

  assert_success
}

@test "generate must succeed when within a git repository, the current directory is not a git repository and there is an argument targeting a git repository. The argument takes precedence" {
  create_git_repository
  commit_with_message 'test: the script location git repository'
  create_git_repository_and_cd_in ../other_git_dir
  commit_with_message 'test: the argument git repository'
  cd ..

  run src/generate.sh -r other_git_dir

  assert_pcre_match "$output" $'# test\n\n^- the argument git repository '"${generate_sha1_pattern}"'$'
}

@test "generate must succeed when within a git repository, the current directory is a git repository and there is no argument specified. The current directory takes precedence" {
  create_git_repository
  commit_with_message 'test: the script location git repository'
  create_git_repository_and_cd_in ../other_git_dir
  commit_with_message 'test: the current directory git repository'

  run ../src/generate.sh

  assert_pcre_match "$output" $'# test\n\n^- the current directory git repository '"${generate_sha1_pattern}"'$'
}

@test "generate must succeeds when within a git repository, the current directory is a git repository and there is an argument targeting a git repository. The argument takes precedence" {
  create_git_repository
  commit_with_message 'test: the script location git repository'
  create_git_repository_and_cd_in ../yet_another_git_dir
  commit_with_message 'test: the argument git repository'
  create_git_repository_and_cd_in ../other_git_dir
  commit_with_message 'test: the current directory git repository'

  run ../src/generate.sh --git-repository ../yet_another_git_dir

  assert_pcre_match "$output" $'# test\n\n^- the argument git repository '"${generate_sha1_pattern}"'$'
}

@test "generate must show the sha1 of each reported commit" {
  create_git_repository
  commit_with_message 'fix: a fix commit'

  run generate.sh

  assert_pcre_match "$output" "### fix

^- a fix commit ${generate_sha1_pattern}$"
}

@test "generate can bump version creating an annotated tag if asked" {
  create_git_repository
  commit_with_message 'feat: a very fancy feature'

  run generate.sh --bump-version

  assert_latest_annotated_tag_equals 'v0.1.0'
}

@test "generate does not bump version creating an annotated tag if not asked" {
  create_git_repository
  commit_with_message 'feat: a very fancy feature'

  run generate.sh

  refute assert_latest_annotated_tag_equals 'v0.1.0'
}

@test "generate can bump version creating an initial annotated tag specified by the user" {
  create_git_repository
  commit_with_message 'feat: a very fancy feature'

  run generate.sh --bump-version --initial-version=v5.0.0

  assert_latest_annotated_tag_equals 'v5.0.0'
}

@test "bumping the same initial version on an already version-bumped repository has no effect" {
  create_git_repository
  commit_with_message 'feat: a very fancy feature'
  ./generate.sh --bump-version

  run generate.sh --bump-version

  assert_success
  assert_latest_annotated_tag_equals 'v0.1.0'
}

@test "bumping version several time with different initial version is meaningless and errors" {
  create_git_repository
  commit_with_message 'feat: a very fancy feature'
  ./generate.sh --bump-version

  run -1 generate.sh --bump-version --initial-version=v1.0.0

  assert_output "${generate_error_bump_version_already_done}"
}

@test "bumping with a non SemVer compliant version string is an error" {
  create_git_repository
  commit_with_message 'feat: a very fancy feature'

  run -1 generate.sh --bump-version --initial-version=wip_non_semver

  assert_output "${generate_error_bump_version_not_semver}"
}

@test "generate output a versioned changelog after a bump" {
  skip "re-think the changelog generation in term of versionned sections"

  # TODO: fix multiline pcre match with begin and end of line
  create_git_repository
  commit_with_message 'feat: a very fancy feature'
  local expected_output_pattern="## \[v0\.1\.0\]

### feat

- a very fancy feature ${generate_sha1_pattern}"

  run generate.sh -b

  assert_output --partial "$generate_changelog_header"
  assert_pcre_match "$output" "$expected_output_pattern"
}

@test "generate output a changelog with both a versionned and an unreleased section after version bump" {
  skip "re-think the changelog generation in term of versionned sections"

  create_git_repository
  commit_with_message 'feat: a very fancy feature'
  ./generate.sh -b > /dev/null
  commit_with_message 'fix: fixing the latest version'
  local expected_output_pattern="## \[Unreleased\]

### fix

- fixing the latest version ${generate_sha1_pattern}

## \[v0\.1\.0\]

### feat

- a very fancy feature ${generate_sha1_pattern}"

  run generate.sh -b

  assert_output --partial "$generate_changelog_header"
  assert_pcre_match "$output" "$expected_output_pattern"
}
