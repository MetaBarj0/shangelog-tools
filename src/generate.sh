#!/bin/sh

ensure_within_git_repository() {
  git status > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    echo "${generate_error_cannot_bind_git_repository}" >&2
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
    --all -E -i --grep \
    "^(${generate_conventional_commit_type_regex})(\(.+\))?: [^ ].*"
}

ensure_there_are_at_least_one_conventional_commit() {
  local changelog_compliant_commits="$(list_changelog_compliant_commits)"

  if [ -z "$changelog_compliant_commits" ]; then
    echo "${generate_error_no_conventional_commit_found}" >&2
    exit 1
  fi
}

generate_commit_type_header() {
  cat << EOF
### $1
EOF
}

generate_commit_type_content_for() {
  local commit_type="$1"
  local commit_lines=
  local commit_sha1=

  while read commit_sha1; do
    local commit_summary="$(git show -s --pretty='format:%s' $commit_sha1)"
    local conventional_commit_header='^('"${commit_type}"')(\(.+\))?: ([^ ].*)'
    local commit_line="$( \
      echo $commit_summary \
        | grep -E \
        "${conventional_commit_header}" \
        | sed -E \
        's/'"${conventional_commit_header}"'/- \2 \3/' \
        | sed -E 's/-  (.+)/- \1/'
    )"

    commit_lines="$(cat << EOF
${commit_lines}
${commit_line}
EOF
    )"
  done << EOF
$(list_changelog_compliant_commits)
EOF

  echo "$commit_lines" | sed -E '/^$/d'
}

initialize_all_commit_type_variables() {
  while read -d '|' commit_type; do
    local commit_type_header="$(generate_commit_type_header $commit_type)"
    local commit_type_content="$(generate_commit_type_content_for $commit_type)"

    if [ -z "${commit_type_content}" ]; then
      continue
    fi

    eval "$(cat << EOF_eval
${commit_type}_paragraph=\$(cat << EOF
\${commit_type_header}

\${commit_type_content}
EOF
)
EOF_eval
    )"
  done << EOF_while
$(echo $generate_conventional_commit_type_regex)|
EOF_while
}

output_all_commit_type_paragraphs() {
  while read -d '|' commit_type; do
    eval "local paragraph=\"\${${commit_type}_paragraph}\""

    if [ -z "${paragraph}" ]; then
      continue
    fi

    echo $'\n'"${paragraph}"
  done << EOF
$(echo $generate_conventional_commit_type_regex)|
EOF
}

output_changelog() {
  initialize_all_commit_type_variables

  echo "${generate_changelog_header}"

  output_all_commit_type_paragraphs
}

load_strings() {
  local script_dirname="$(dirname "$0")"
  cd "$script_dirname" >/dev/null 2>&1
  local script_dir="$(pwd -P)"
  cd - >/dev/null 2>&1

  source "${script_dir}/generate.sh.d/strings.sh"
}

change_current_directory() {
  if [ ! -z "$1" ]; then
    cd "$1"
  fi
}

main() {
  load_strings
  change_current_directory "$1"
  ensure_within_git_repository
  ensure_there_are_commits
  ensure_there_are_no_pending_changes
  ensure_there_are_at_least_one_conventional_commit

  output_changelog
}

main $@
