#!/bin/sh

get_script_dir() {
  local script_dirname="$(dirname "$0")"
  cd "$script_dirname" >/dev/null 2>&1
  pwd -P
  cd - >/dev/null 2>&1
}

load_functions() {
  local script_dir="$(get_script_dir)"

  source "${script_dir}/generate.sh.d/functions.sh"
  load_strings "${script_dir}"
}

parse_arguments() {
  initialize_argument_default_values

  local valid_args \
  && valid_args="$(getopt -q -o br:i:h --long bump-version,git-repository:,initial-version:,help -- $@)"

  if [ $? -ne 0 ]; then
    show_help
  fi

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
      -h | --help)
        show_help
        shift
        break
        ;;
      --)
        shift
        break
        ;;
      \?)
        show_help
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

ensure_there_are_at_least_one_conventional_commit() {
  if ! is_there_any_conventional_commit; then
    echo "${generate_error_no_conventional_commit_found}" >&2
    exit 1
  fi
}

is_repository_already_versionned() {
  [ $(get_all_semver_tags_from_newest_to_oldest | wc -l) -gt 0 ]
}

bump_initial_version() {
  git tag -am 'initial version' "$initial_version"
}

bump_next_version() {
  local latest_version="$(get_all_semver_tags_from_newest_to_oldest | head -n 1)"
}

bump_version_if_asked() {
  if [ ! "$bump_version_asked" = 'true' ]; then
    return 0
  fi

  if ! is_repository_already_versionned; then
    bump_initial_version

    return $?
  fi

  bump_next_version
}

output_changelog() {
  local header="${generate_changelog_header}"
  local sections \
  && sections="$(generate_sections)" || return $?

  echo "$header"
  echo "$sections"
}

main() {
  load_functions \
  && parse_arguments "$@" \
  && change_current_directory "$git_repository_directory" \
  && ensure_targeting_git_repository \
  && ensure_there_are_commits \
  && ensure_there_are_no_pending_changes \
  && ensure_there_are_at_least_one_conventional_commit \
  && bump_version_if_asked \
  && output_changelog
}

main $@
