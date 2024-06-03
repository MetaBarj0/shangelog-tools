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
  load 'helpers/expected.sh'

  cp -r src "$BATS_TEST_TMPDIR"
  cd "$BATS_TEST_TMPDIR/src"

  . generate.sh.d/strings.sh

  PATH="${BATS_TEST_TMPDIR}/src:${PATH}"
}

teardown() {
  cd /root/ringover-shangelog-tools
}

@test "generate fails with '1' if not targeting git repository" {
  run -1 generate_in_docker

  assert_output "${generate_error_cannot_bind_git_repository}"
}

@test "generate fails if the git repository does not have any commit" {
  create_git_repository

  run -1 generate_in_docker

  assert_output "${generate_error_no_commits}"
}

@test "generate fails if there is pending changes in the targeted repository" {
  create_git_repository
  commit_with_message 'chore: First conventional chore commit'
  touch pending.txt
  git add pending.txt

  run -1 generate_in_docker

  assert_output "$generate_error_pending_changes"
}

@test "generate fails if it does not find any conventional commit in the history" {
  create_git_repository
  commit_with_message 'non conventional commit'
  commit_with_message 'chore:'
  commit_with_message 'chore:       too much spaces'
  commit_with_message 'chore(scope):       too much spaces'

  run -1 generate_in_docker

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

  run generate_in_docker

  assert_output --partial "${generate_changelog_header}"
  assert_pcre_match_output "${expected_output_pattern}"
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

  run generate_in_docker

  assert_output --partial "${generate_changelog_header}"
  assert_pcre_match_output "${expected_output_pattern}"
}

@test "generates handles correctly interleaved conventional commit types" {
  create_git_repository
  commit_with_message 'feat: Initial commit'
  commit_with_message 'chore(a chore scope): Second commit, chore one'
  commit_with_message 'non conventional commit in the branch'
  commit_with_message 'feat(last feature): latest fancy feature'
  commit_with_message 'chore(style): reformat, more stylish'

  run generate_in_docker

  assert_output --partial "${generate_changelog_header}"
  assert_pcre_match_output "^## \[Unreleased\]$

^### feat$

^- \(last feature\) latest fancy feature ${generate_sha1_pattern}$
^- Initial commit ${generate_sha1_pattern}$"

  assert_pcre_match_output "^### chore$

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

  run generate_in_docker

  assert_output --partial "${generate_changelog_header}"
  assert_output --partial "## [Unreleased]"
  assert_pcre_match_output $'^### revert$\n\n'"^- a revert commit ${generate_sha1_pattern}$"
  assert_pcre_match_output $'^### test$\n\n'"^- a test commit ${generate_sha1_pattern}$"
  assert_pcre_match_output $'^### perf$\n\n'"^- a perf commit ${generate_sha1_pattern}$"
  assert_pcre_match_output $'^### refactor$\n\n'"^- a refactor commit ${generate_sha1_pattern}$"
  assert_pcre_match_output $'^### style$\n\n'"^- a style commit ${generate_sha1_pattern}$"
  assert_pcre_match_output $'^### docs$\n\n'"^- a docs commit ${generate_sha1_pattern}$"
  assert_pcre_match_output $'^### ci$\n\n'"^- a ci commit ${generate_sha1_pattern}$"
  assert_pcre_match_output $'^### chore$\n\n'"^- a chore commit ${generate_sha1_pattern}$"
  assert_pcre_match_output $'^### build$\n\n'"^- a build commit ${generate_sha1_pattern}$"
  assert_pcre_match_output $'^### feat$\n\n'"^- a feat commit ${generate_sha1_pattern}$"
  assert_pcre_match_output $'^### fix$\n\n'"^- a fix commit ${generate_sha1_pattern}$"
}

@test "generate must fail if invoked outside of a git repository and the current directory is not a git repository and there is no argument specified" {
  mkdir inner_directory
  cd inner_directory

  run -1 generate_in_docker

  assert_output "${generate_error_cannot_bind_git_repository}"
}

@test "generate must succeed when invoked outside of a git repository, the current directory is not a git repository and the argument targets a git repository" {
  create_git_repository_and_cd_in ../inner_git_dir
  commit_with_message 'chore: a first commit'
  cd -
  override_repository_directory_for_bind_mount_with ../inner_git_dir

  run generate_in_docker -r ../inner_git_dir

  assert_success
}

@test "generate must succeed when outside of a git repository, the current directory is a git repository, with no argument specified" {
  create_git_repository_and_cd_in ../inner_git_dir
  commit_with_message 'chore: a first commit'

  run generate_in_docker

  assert_success
}

@test "generate must succeed when outside of a git repository, the current directory being a git repository and an argument target a git repository. The argument takes precedence" {
  create_git_repository_and_cd_in ../other_git_dir
  commit_with_message 'test: the argument git repository'
  create_git_repository_and_cd_in ../yet_another_git_dir
  commit_with_message 'test: the current directory git repository'
  override_repository_directory_for_bind_mount_with ../other_git_dir

  run generate_in_docker -r ../other_git_dir

  assert_pcre_match_output $'^### test$\n\n^- the argument git repository '"${generate_sha1_pattern}$"
}

@test "generate must succeed when within a git repository, the current directory is not a git repository and there is no argument specified" {
  create_git_repository
  commit_with_message 'fix: a fix commit'
  cd ..

  run generate_in_docker

  assert_success
}

@test "generate must succeed when within a git repository, the current directory is not a git repository and there is an argument targeting a git repository. The argument takes precedence" {
  create_git_repository
  commit_with_message 'test: the script location git repository'
  create_git_repository_and_cd_in ../other_git_dir
  commit_with_message 'test: the argument git repository'
  cd ..
  override_repository_directory_for_bind_mount_with other_git_dir

  run generate_in_docker -r other_git_dir

  assert_pcre_match_output $'^### test$\n\n^- the argument git repository '"${generate_sha1_pattern}$"
}

@test "generate must succeed when within a git repository, the current directory is a git repository and there is no argument specified. The current directory takes precedence" {
  create_git_repository
  commit_with_message 'test: the script location git repository'
  create_git_repository_and_cd_in ../other_git_dir
  commit_with_message 'test: the current directory git repository'

  run generate_in_docker

  assert_pcre_match_output $'^### test$\n\n^- the current directory git repository '"${generate_sha1_pattern}$"
}

@test "generate in docker must succeeds when within a git repository, the current directory is a git repository and there is an argument targeting a git repository. The argument takes precedence" {
  create_git_repository
  commit_with_message 'test: the script location git repository'
  create_git_repository_and_cd_in ../yet_another_git_dir
  commit_with_message 'test: the argument git repository'
  create_git_repository_and_cd_in ../other_git_dir
  commit_with_message 'test: the current directory git repository'
  override_script_directory_for_bind_mount
  override_current_directory_for_bind_mount
  override_repository_directory_for_bind_mount_with ../yet_another_git_dir

  run ../src/generate.sh --git-repository ../yet_another_git_dir

  assert_pcre_match_output $'^### test$\n\n^- the argument git repository '"${generate_sha1_pattern}$"
}

@test "generate must show the sha1 of each reported commit" {
  create_git_repository
  commit_with_message 'fix: a fix commit'

  run generate_in_docker

  assert_pcre_match_output "^### fix$

^- a fix commit ${generate_sha1_pattern}$"
}

@test "generate can bump version creating an annotated tag if asked" {
  create_git_repository
  commit_with_message 'feat: a very fancy feature'

  run generate_in_docker --bump-version

  assert_latest_annotated_tag_equals 'v0.1.0'
}

@test "generate does not bump version creating an annotated tag if not asked" {
  create_git_repository
  commit_with_message 'feat: a very fancy feature'

  run generate_in_docker

  refute assert_latest_annotated_tag_equals 'v0.1.0'
}

@test "generate can bump version creating an initial annotated tag specified by the user" {
  create_git_repository
  commit_with_message 'feat: a very fancy feature'

  run generate_in_docker --bump-version --initial-version=v5.0.0

  assert_latest_annotated_tag_equals 'v5.0.0'
}

@test "bumping the same initial version on an already version-bumped repository has no effect" {
  create_git_repository
  commit_with_message 'feat: a very fancy feature'
  generate_in_docker --bump-version

  run generate_in_docker --bump-version

  assert_success
  assert_latest_annotated_tag_equals 'v0.1.0'
}

@test "bumping version several time with different initial version has no effect after the first bump" {
  create_git_repository
  commit_with_message 'feat: a very fancy feature'
  generate_in_docker --bump-version

  run generate_in_docker --bump-version --initial-version=v1.0.0

  assert_success
  assert_latest_annotated_tag_equals 'v0.1.0'
}

@test "bumping with a non SemVer compliant version string is an error" {
  create_git_repository
  commit_with_message 'feat: a very fancy feature'

  run -1 generate_in_docker --bump-version --initial-version=wip_non_semver

  assert_output "${generate_error_bump_version_not_semver}"
}

@test "generate output a versioned changelog after a bump" {
  create_git_repository
  commit_with_message 'feat: a very fancy feature'
  local expected_output_pattern="^## \[v0\.1\.0\]$

^### feat$

^- a very fancy feature ${generate_sha1_pattern}$"

  run generate_in_docker -b

  assert_output --partial "$generate_changelog_header"
  assert_pcre_match_output "$expected_output_pattern"
}

@test "generate in docker bump version create a commit containing a CHANGELOG.md file both in local and in remote" {
  create_remote_git_repository_and_clone_it
  commit_with_message_and_push_to_remote 'feat: a very fancy feature'
  bump_version
  commit_with_message 'feat: another very fancy feature'

  run generate_in_docker -b

  assert_changelog_commit_at_tip
  assert_same_tip_commit_local_remote
}

@test "generate output a changelog with both a versionned and an unreleased section after version bump" {
  create_git_repository
  commit_with_message 'feat: a very fancy feature'
  bump_version
  commit_with_message 'fix: fixing the latest version'
  local expected_output_pattern="^## \[Unreleased\]$

^### fix$

^- fixing the latest version ${generate_sha1_pattern}$

^## \[v0\.1\.0\]$

^### feat$

^- a very fancy feature ${generate_sha1_pattern}$"

  run generate_in_docker

  assert_output --partial "$generate_changelog_header"
  assert_pcre_match_output "$expected_output_pattern"
}

@test "generate output a correct changelog between 2 merge commits as annotated tags" {
  create_git_repository
  commit_with_message 'feat: a very fancy feature'
  switch_to_branch 'fix1'
  commit_with_message 'fix: urgent fix'
  switch_to_branch 'master'
  merge_no_ff 'fix1'
  create_annotated_tag 'v0.1.0'
  switch_to_branch 'fix2'
  commit_with_message 'fix: another urgent fix'
  switch_to_branch 'master'
  merge_no_ff 'fix2'
  create_annotated_tag 'v0.2.0'

  run generate_in_docker

  assert_pcre_match_output "$(merge_tests_expected_output_pattern)"
}

@test "generate output a correct changelog between merge and normal commits as annotated tags" {
  create_git_repository
  commit_with_message 'feat: a very fancy feature'
  commit_with_message 'fix: urgent fix'
  create_annotated_tag 'v0.1.0'
  switch_to_branch 'fix2'
  commit_with_message 'fix: another urgent fix'
  switch_to_branch 'master'
  merge_no_ff 'fix2'
  create_annotated_tag 'v0.2.0'

  run generate_in_docker

  assert_pcre_match_output "$(merge_tests_exepcted_output_pattern)"
}

@test "generate does not output a changelog with empty version containing wrong commits" {
  create_git_repository
  commit_with_message 'non conventional commit 1'
  commit_with_message 'non conventional commit 2'
  create_annotated_tag 'v0.1.0'
  commit_with_message 'non conventional commit 3'
  commit_with_message 'non conventional commit 4'
  create_annotated_tag 'v0.2.0'
  commit_with_message 'chore: under the top commit'
  commit_with_message 'feat: top commit'

  run generate_in_docker

  refute assert_pcre_match_output "$(empty_commit_incorrect_pattern)"
}

@test "generate output a correct changelog between normal and merge commits as annotated tags" {
  create_git_repository
  commit_with_message 'feat: a very fancy feature'
  switch_to_branch 'fix1'
  commit_with_message 'fix: urgent fix'
  switch_to_branch 'master'
  merge_no_ff 'fix1'
  create_annotated_tag 'v0.1.0'
  commit_with_message 'fix: another urgent fix'
  create_annotated_tag 'v0.2.0'

  run generate_in_docker

  assert_pcre_match_output "$(merge_tests_exepcted_output_pattern)"
}

@test "generate can recognize breaking change commit title" {
  create_git_repository
  commit_with_message 'feat: a new API'
  commit_with_message 'fix!: a breaking fix'
  commit_with_message 'chore(deprecation)!: a breaking tidying'

  run generate_in_docker

  assert_pcre_match_output "^## \[Unreleased\]$"
  assert_pcre_match_output "^### chore$"
  assert_pcre_match_output "^- \(deprecation\) a breaking tidying ${generate_sha1_pattern}$"
  assert_pcre_match_output "^### fix$"
  assert_pcre_match_output "^- a breaking fix ${generate_sha1_pattern}$"
  assert_pcre_match_output "^### feat$"
  assert_pcre_match_output "^- a new API ${generate_sha1_pattern}$"
}

@test "generate bumping version increase the patch number for all commit types but feat and any breaking commits" {
  create_git_repository
  commit_with_message 'docs: a first readme'
  bump_version
  commit_with_message 'fix: small fix'
  bump_version
  commit_with_message 'build: build script'
  bump_version
  commit_with_message 'chore: readme tidying'
  bump_version
  commit_with_message 'ci: initializing'
  bump_version
  commit_with_message 'docs: added stuff in readme'
  bump_version
  commit_with_message 'style: added a tool to handle this for us'
  bump_version
  commit_with_message 'refactor: ci scripts'
  bump_version
  commit_with_message 'perf: enhanced ci build speed'
  bump_version
  commit_with_message 'test: changed test framework'
  bump_version
  commit_with_message 'revert: get back with the older test framework after all'

  run generate_in_docker --bump-version

  assert_pcre_match_output "^## \[v0.1.10\]$"
}

@test "generate bumping version increase the minor number only for fix commit type that are not breaking" {
  create_git_repository
  commit_with_message 'docs: a first readme'
  bump_version
  commit_with_message 'chore: some tidying'
  bump_version
  commit_with_message 'feat: an awesome addition'
  commit_with_message 'test: tests are awesome'

  run generate_in_docker --bump-version

  assert_pcre_match_output "^## \[v0.2.0\]$"
}

@test "generate bumping version increase the major number only for breaking changes" {
  create_git_repository
  commit_with_message 'docs: a first readme'
  bump_version
  commit_with_message 'chore!: some breaking tidying'
  commit_with_message 'feat: an awesome addition'
  bump_version
  commit_with_message 'fix: a fix'
  bump_version
  commit_with_message "test: breaking tests are awesome

BREAKING CHANGE: this test breaks the world"
  bump_version
  commit_with_message "fix: breaking fixes are awesome

BREAKING-CHANGE: breaking fix of the ..."

  run generate_in_docker --bump-version

  assert_pcre_match_output "^## \[v3.0.0\]$"
}

@test "generate bumping version can does not change major on misplaced breaking change footer" {
  create_git_repository
  commit_with_message 'docs: a first readme'
  bump_version
  commit_with_message 'chore!: some breaking tidying'
  commit_with_message 'feat: an awesome addition'
  bump_version
  commit_with_message "feat: a mistakenly non breaking feat

Move your body!!!
BREAKING CHANGE: nope, you missed the breaking change

DAMN-FOOTER:not interpreted"

  run generate_in_docker --bump-version

  refute assert_pcre_match_output "^## \[v2.0.0\]$"
}
