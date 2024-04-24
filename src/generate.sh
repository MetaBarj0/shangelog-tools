#!/bin/sh

load_strings() {
  local script_dirname="$(dirname "$0")"
  cd "$script_dirname" >/dev/null 2>&1
  local script_dir="$(pwd -P)"
  cd - >/dev/null 2>&1

  source "${script_dir}/generate.sh.d/strings.sh"
}

initialize_argument_default_values() {
  initial_version=v0.1.0
}

ensure_arguments_are_valid() {
  echo "$initial_version" | pcregrep "${generate_semver_regex}" > /dev/null
}

parse_arguments() {
  initialize_argument_default_values

  local valid_args="$(getopt -o br:i: --long bump-version,git-repository:,initial-version: -- $@)"

  eval set -- "$valid_args"

  while true; do
    case "$1" in
      -b | --bump-version)
        bump_version_asked=true
        shift
        ;;
      -r | --git-repository)
        git_repository_directory="$2"
        shift 2
        ;;
      -i | --initial-version)
        initial_version="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
    esac
  done

  ensure_arguments_are_valid
}

change_current_directory() {
  if [ ! -z "$1" ]; then
    cd "$1"
  fi
}

ensure_current_directory_is_git_repository() {
  git status > /dev/null 2>&1
}

ensure_script_is_within_git_repository() {
  if [ $? -ne 0 ]; then
    local script_dirname="$(dirname "$0")"
    cd "$script_dirname" >/dev/null 2>&1
  fi

  ensure_current_directory_is_git_repository
}

ensure_targeting_git_repository() {
  ensure_current_directory_is_git_repository \
  || ensure_script_is_within_git_repository

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

  echo "${changelog_compliant_commits}"
}

generate_commit_type_header() {
  cat << EOF
### $1
EOF
}

generate_commit_type_content_for() {
  local commit_type="$1"
  local changelog_compliant_commits="$2"
  local commit_lines=
  local commit_sha1=

  while read commit_sha1; do
    local commit_summary="$(git show -s --pretty='format:%s' $commit_sha1)"
    local conventional_commit_header='^('"${commit_type}"')(\(.+\))?: ([^ ].*)'
    local sha1="$(echo ${commit_sha1} | cut -c 0-8)"
    local commit_line="$( \
      echo $commit_summary \
      | grep -E \
        "${conventional_commit_header}" \
      | sed -E \
        's/'"${conventional_commit_header}"'/- \2 \3 ['"${sha1}"']/' \
      | sed -E \
        's/-  (.+)/- \1/'
    )"

    commit_lines="$(cat << EOF
${commit_lines}
${commit_line}
EOF
    )"
  done << EOF
${changelog_compliant_commits}
EOF

  echo "$commit_lines" | sed -E '/^$/d'
}

initialize_all_commit_type_variables() {
  local changelog_compliant_commits="$1"

  while read -d '|' commit_type; do
    local commit_type_header="$(generate_commit_type_header $commit_type)"
    local commit_type_content="$(generate_commit_type_content_for $commit_type "${changelog_compliant_commits}")"

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
  local changelog_compliant_commits="$1"

  initialize_all_commit_type_variables "${changelog_compliant_commits}"

  echo "${generate_changelog_header}"

  output_all_commit_type_paragraphs
}

bump_version_if_asked() {
  if [ ! "$bump_version_asked" = 'true' ]; then
    return 0
  fi

  local describe_output="$(git describe --abbrev=0 2>/dev/null)"

  if [ "$describe_output" = "$initial_version" ]; then
    return 0
  fi

  if [ ! -z "$describe_output" ] && [ ! "$describe_output" = "$initial_version" ]; then
    echo "$generate_error_bump_version_already_done" >&2
    return 1
  fi

  git tag -am 'placeholder' "$initial_version"
}

main() {
  load_strings \
  && parse_arguments "$@" \
  && change_current_directory "$git_repository_directory" \
  && ensure_targeting_git_repository \
  && ensure_there_are_commits \
  && ensure_there_are_no_pending_changes \
  && local changelog_compliant_commits \
  && changelog_compliant_commits="$(ensure_there_are_at_least_one_conventional_commit)" \
  && bump_version_if_asked \
  && output_changelog "${changelog_compliant_commits}"
}

main $@
