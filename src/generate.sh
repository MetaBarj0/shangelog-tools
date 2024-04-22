#!/bin/sh

ensure_within_git_repository() {
  git status > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    echo "${generate_error_not_git_repository}" >&2
    exit 1
  fi
}

ensure_there_are_commits() {
  local commit_count=$(git rev-list --all | wc -l)
  if [ $commit_count -lt 1 ]; then
    echo "${generate_error_no_commits}" >&2
    exit 1
  fi
}

ensure_there_are_no_pending_changes() {
  local pending_changes="$(git status --porcelain=v1 -uno)"

  if [ ! -z "$pending_changes" ]; then
    echo "${generate_error_pending_changes}" >&2

    exit 1
  fi
}

list_changelog_compliant_commits() {
  git rev-list \
    --all --reverse -E -i --grep \
    "^(${generate_conventional_commit_type_regex})(\(.+\))?: [^ ].*"
}

ensure_there_are_at_least_one_conventional_commit() {
  local changelog_compliant_commits="$(list_changelog_compliant_commits)"

  if [ -z "$changelog_compliant_commits" ]; then
    echo "${generate_error_no_conventional_commit_found}" >&2
    exit 1
  fi
}

generate_changelog_header() {
  cat << EOF
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
EOF
}

generate_unreleased_header() {
  cat << EOF
## [Unreleased]
EOF
}

generate_commit_type_header() {
  cat << EOF
### chore
EOF
}

generate_commit_type_content() {
  local commit_lines=
  local commit_sha1=

  while read commit_sha1; do
    local commit_summary="$(git show -s --pretty='format:%s' $commit_sha1)"
    local commit_line="$( \
      echo $commit_summary \
        | sed -E \
        's/^('"${generate_conventional_commit_type_regex}"')(\(.+\))?: ([^ ].*)/- \3/')"

    commit_lines="$(cat << EOF
${commit_lines}
${commit_line}
EOF
    )"
  done << EOF
$(list_changelog_compliant_commits)
EOF

  echo "$commit_lines"
}

output_changelog() {
  local changelog_header="$(generate_changelog_header)"
  local unreleased_header="$(generate_unreleased_header)"
  local commit_type_header="$(generate_commit_type_header)"
  local commit_type_content="$(generate_commit_type_content)"

  cat << EOF
${changelog_header}

${unreleased_header}

${commit_type_header}
${commit_type_content}
EOF
}

main() {
  source ./generate.sh.d/strings.sh

  ensure_within_git_repository
  ensure_there_are_commits
  ensure_there_are_no_pending_changes
  ensure_there_are_at_least_one_conventional_commit

  output_changelog
}

main
