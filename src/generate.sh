#!/bin/sh

ensure_within_git_repository() {
  git status > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    echo 'Error: this script must be run within a git repository' >&2
    exit 1
  fi
}

ensure_there_are_commits() {
  local commit_count=$(git rev-list --all | wc -l)
  if [ $commit_count -lt 1 ]; then
    echo 'Error: the git repository does not contain any commit' >&2
    exit 1
  fi
}

ensure_there_are_no_pending_changes() {
  local pending_changes="$(git status --porcelain=v1 -uno)"

  if [ ! -z "$pending_changes" ]; then
    cat >&2 << EOF
Error: there are pending changes in the repository. Commit, discard or stash
them before going any further.
EOF

    exit 1
  fi
}

list_changelog_compliant_commits() {
  git rev-list \
    --all --reverse -E -i --grep \
    '^(chore)(\(.+\))?!?: [^ ].*'
}

ensure_there_are_at_least_one_conventional_commit() {
  local changelog_compliant_commits="$(list_changelog_compliant_commits)"

  if [ -z "$changelog_compliant_commits" ]; then
    echo 'Error: no suitable commit found to generate the change log'
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

generate_chore_header() {
  cat << EOF
### chore
EOF
}

generate_chore_content() {
  local chore_lines=
  local commit_sha1=

  while read commit_sha1; do
    local commit_summary="$(git show -s --pretty='format:%s' $commit_sha1)"
    local chore_line="$(echo $commit_summary | sed -E 's/^(chore)(\(.+\))?!?: ([^ ].*)/- \3/')"
    chore_lines="$(cat << EOF
${chore_lines}
${chore_line}
EOF
    )"
  done << EOF
$(list_changelog_compliant_commits)
EOF

  echo "$chore_lines"
}

output_changelog() {
  local changelog_header="$(generate_changelog_header)"
  local unreleased_header="$(generate_unreleased_header)"
  local chore_header="$(generate_chore_header)"
  local chore_content="$(generate_chore_content)"

  cat << EOF
${changelog_header}

${unreleased_header}

${chore_header}
${chore_content}
EOF
}

main() {
  ensure_within_git_repository
  ensure_there_are_commits
  ensure_there_are_no_pending_changes
  ensure_there_are_at_least_one_conventional_commit

  output_changelog
}

main
