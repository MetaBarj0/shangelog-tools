#!/bin/sh

assert_pcre_match_output() {
  if [ $# -ne 1 ]; then
    echo 'assert_pcre_match must be called with 1 arguments: <pattern>' >&2
    exit 1
  fi

  local pattern="$1"

  assert echo "${output}" | pcregrep -M "$pattern"
}

assert_line_count_equals() {
  local input="$1"
  local expected="$2"

  assert [ $(get_line_count "$input") -eq $expected ]
}

assert_latest_annotated_tag_equals() {
  local expected="$1"

  [ "$(git describe --abbrev=0)" = "$expected" ]
}

assert_changelog_commit_at_tip() {
  local files="$(git diff-tree --no-commit-id --name-only --root -r HEAD)"
  local commit_summary="$(git show -s --pretty='format:%s' HEAD)"

  [ "${files}" = "CHANGELOG.md" ] \
  && [ "${commit_summary}" = "bump version" ] \
  && [ "$(cat CHANGELOG.md)" = "${output}" ]
}

assert_same_tip_commit_local_remote() {
  local current_branch="$(git symbolic-ref --short HEAD)"
  local local_HEAD_sha1="$(git show -s --pretty='format:%H' ${current_branch})"
  local remote_HEAD_sha1="$(git show -s --pretty='format:%H' origin/${current_branch})"

  [ "${local_HEAD_sha1}" = "${remote_HEAD_sha1}" ]
}
