#!/bin/sh

inc() {
  bc << EOF
  $1 + 1
EOF
}

print_random_small_string() {
  dd if=/dev/urandom ibs=8 count=1 status=none | base64
}

get_script_directory() {
  if [ -z "${SCRIPT_DIRECTORY_OVERRIDE}" ]; then
    echo "$(get_script_directory_before_override)"
  else
    echo "${SCRIPT_DIRECTORY_OVERRIDE}"
  fi
}

get_current_directory() {
  if [ -z "${CURRENT_DIRECTORY_OVERRIDE}" ]; then
    pwd -P
  else
    echo "${CURRENT_DIRECTORY_OVERRIDE}"
  fi
}

load_strings() {
  local script_dir="$1"

  source "${script_dir}/generate.sh.d/strings.sh"
}

parse_arguments() {
  initialize_argument_default_values

  local valid_args \
  && valid_args="$(getopt -q -o br:i:hn --long bump-version,git-repository:,initial-version:,help,no-docker -- $@)"

  if [ $? -ne 0 ]; then
    show_help 1
  fi

  eval set -- "$valid_args"

  while true; do
    case "$1" in
      -b | --bump-version)
        bump_version_asked='true'
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
      -n | --no-docker)
        no_docker_asked='true'
        shift
        break
        ;;
      --)
        shift
        break
        ;;
    esac
  done

  ensure_arguments_are_valid
}

initialize_argument_default_values() {
  bump_version_asked='false'
  initial_version='v0.1.0'
  no_docker_asked='false'
}

ensure_arguments_are_valid() {
  echo "$initial_version" | pcregrep "${generate_semver_regex}" > /dev/null
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

generate_commit_type_header() {
  cat << EOF
### $1
EOF
}

show_commit_summary() {
  local commit_sha1="$1"

  git show -s --pretty='format:%s' $commit_sha1
}

generate_commit_type_content_for() {
  local commit_type="$1"
  local changelog_compliant_commits="$2"
  local commit_lines=
  local commit_sha1=

  while read commit_sha1; do
    local commit_summary="$(show_commit_summary $commit_sha1)"
    local conventional_commit_header="^(${commit_type})${generate_conventional_commit_scope_title_regex}"
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

get_latest_tag() {
  get_all_semver_tags_from_newest_to_oldest | head -n 1
}

list_changelog_compliant_commits_reachable_from() {
  local end_rev="$1"

  git rev-list \
    -E -i --grep \
    "^(${generate_conventional_commit_type_regex})${generate_conventional_commit_scope_title_regex}" \
    "${end_rev}"
}

is_there_any_conventional_commit() {
  [ $(git rev-list \
        --count -E -i --grep \
        "^(${generate_conventional_commit_type_regex})${generate_conventional_commit_scope_title_regex}" \
        "$(git branch --show-current)") -gt 0 ]
}

list_changelog_compliant_commits_from_rev_to_tip() {
  local rev="$1"

  local rev_option \
  && [ ! -z "$rev" ] \
  && rev_option="^${rev}" \
  || rev_option="$(git branch --show-current)"

  git rev-list \
    -E -i --grep \
    "^(${generate_conventional_commit_type_regex})${generate_conventional_commit_scope_title_regex}" \
    HEAD "${rev_option}"
}

list_changelog_compliant_commits_from_and_up_to() {
  local begin_rev="$1"
  local end_rev="$2"

  git rev-list \
    -E -i --grep \
    "^(${generate_conventional_commit_type_regex})${generate_conventional_commit_scope_title_regex}" \
    "${begin_rev}" ^"${end_rev}"
}

output_section_header() {
  local header_name="$1"

  echo $'\n'"## [$1]"
}

output_all_commit_type_paragraphs() {
  local changelog_compliant_commits="$1"

  while read -d '|' commit_type; do
    local commit_type_header="$(generate_commit_type_header $commit_type)"
    local commit_type_content="$(generate_commit_type_content_for $commit_type "${changelog_compliant_commits}")"

    if [ -z "${commit_type_content}" ]; then
      continue
    fi

    eval "$(cat << EOF_eval
local ${commit_type}_paragraph=\$(cat << EOF
\${commit_type_header}

\${commit_type_content}
EOF
)
EOF_eval
    )"
  done << EOF_while
$(echo $generate_conventional_commit_type_regex)|
EOF_while

  while read -d '|' commit_type; do
    eval "local paragraph=\"\${${commit_type}_paragraph}\""

    [ -z "${paragraph}" ] && continue

    echo $'\n'"${paragraph}"
  done << EOF
$(echo $generate_conventional_commit_type_regex)|
EOF
}

output_section() {
  local header="$1"
  local commits="$2"

  output_section_header "$header"
  output_all_commit_type_paragraphs "${commits}"
}

list_unreleased_changelog_compliant_commits() {
  local latest_tag="$(get_latest_tag)"

  list_changelog_compliant_commits_from_rev_to_tip ${latest_tag}
}

generate_unreleased_section() {
  local commits="$(list_unreleased_changelog_compliant_commits)"

  [ -z "$commits" ] && return 0

  output_section 'Unreleased' "${commits}"
}

generate_versioned_section() {
  local upper_tag="$(echo "$1" | head -n 1)"
  local lower_tag="$2"

  local commits
  if [ -z "$lower_tag" ]; then
    commits="$(list_changelog_compliant_commits_reachable_from $upper_tag)"
  else
    commits="$(list_changelog_compliant_commits_from_and_up_to $upper_tag $lower_tag)"
  fi

  output_section "${upper_tag}" "${commits}"

  local next_tags="$(echo "$1" | sed '1d')"
  local next_lower_tag="$(echo "$next_tags" | sed '1d' | head -n 1)"

  [ ! -z "$lower_tag" ] \
  && generate_versioned_section "$next_tags" "$next_lower_tag"

  return 0
}

get_all_sorted_annotated_tags() {
  git for-each-ref --format='%(objecttype) %(refname:short)' --sort='v:refname' | grep tag | sed 's/^tag //'
}

get_all_semver_tags_from_newest_to_oldest() {
  get_all_sorted_annotated_tags \
  | pcregrep "${generate_semver_regex}" \
  | tac
}

generate_versioned_sections() {
  local tags="$(get_all_semver_tags_from_newest_to_oldest)"

  [ -z "$tags" ] && return 0

  local lower_tag="$(echo "$tags" | sed '1d' | head -n 1)"

  generate_versioned_section "$tags" "$lower_tag"
}

generate_sections() {
  generate_unreleased_section \
  && generate_versioned_sections
}

show_help() {
  local exit_code="${1:-0}"

  cat << EOF
usage: generate.sh [-h | --help] [-b | --bump-version]
                   [-i | --initial-version] [-r | --git-repository]
                   [-n | --no-docker]

Output the changelog of a chosen git repository.

Options:

  -h  --help

      Display this message.

  -b  --bump-version

      Create an annotated tag at the tip of the current branch. The tag will
      be named according the SemVer convention and be calculated
      automatically depending the conventional commit type found from either
      the latest annotated SemVer compliant tag or the root of the git
      repository.

  -i version | --initial-version=version

      The initial version to set when using -b or --bump-version on a git
      repository that does not have any SemVer annotated tag yet.

  -r directory | --git-repository=directory

      The git repository to target. Useful when the generate.sh script is not
      within a git repository or the current directory is not the git directory
      you want to generate a changelog from.

  -n | --no-docker

      Do not invoke this script within a docker container. It is useful if you
      want to run it on a GNU environment because this script relies heavily on
      GNU tools.
      By design, this tool has been thought to be run on any platform that
      supports docker container execution. If this option is not specified, an
      image is built and a container is run using it. At the end of the
      invocation, everything is removed (but the build cache, for obvious
      performance reasons) as if this script was run on the host machine.

Examples:

  Given you're in the generate.sh directory:

    ./generate.sh will print the changelog on the standard output.

    ./generate.sh -b will print the changelog on the standard output and bump
    the currently unreleased changes on the respository. Bumping the version
    means creating an annotated tag at the tip of the current branch. If this
    is the first time you bump the version and you do not specify the
    --initial-version option, v0.1.0 will be used by default.

    ./generate.sh -b -i v1.0.0 will print the changelog on the standard output
    and bump the currently unreleased changes on the respository to the
    'v1.0.0' version. You MUST use a SemVer compliant version for the '-i'
    option otherwise the script exits with an error.
EOF

  exit $exit_code
}

is_repository_already_versionned() {
  [ $(get_all_semver_tags_from_newest_to_oldest | wc -l) -gt 0 ]
}

bump_initial_version() {
  git tag -am 'initial version' "$initial_version"
}

show_commit_body() {
  local commit_sha1="$1"

  git show -s --pretty='format:%b' $commit_sha1
}

is_it_breaking_commit_summary() {
  local commit_summary="$1"
  local breaking_commit_summary_pattern="(${generate_conventional_commit_type_regex})${generate_conventional_breaking_commit_scope_title_regex}"

  echo "$commit_summary" | grep -E "${breaking_commit_summary_pattern}" >/dev/null
}

extract_footer() {
  local body="$(echo "$1" | tac)"
  local footer

  while read line; do
    if [ -z "$line" ]; then
      break
    fi

    footer="$footer"$'\n'"$line"
  done << EOF
$body
EOF

  echo "$footer" | sed -E '1d'
}

is_it_breaking_commit_body() {
  local commit_body="$1"
  local footer="$(extract_footer "$commit_body")"
  local breaking_commit_footer_pattern="^BREAKING( |-)CHANGE: .+$"

  echo "$footer" | grep -E "${breaking_commit_footer_pattern}" >/dev/null
}

is_there_breaking_changes() {
  while read commit_sha1; do
    local commit_summary="$(show_commit_summary $commit_sha1)"
    local commit_body="$(show_commit_body $commit_sha1)"

    is_it_breaking_commit_summary "$commit_summary" \
    && return 0 \
    || is_it_breaking_commit_body "$commit_body" \
    && return 0
  done << EOF
$(list_unreleased_changelog_compliant_commits)
EOF

  return 1
}

bump_next_major() {
  if ! is_there_breaking_changes; then
    return 1
  fi

  local major_number="$(get_latest_tag | sed -r 's/'${generate_semver_regex}'/\1/')"
  local new_major_number="$(inc $major_number)"

  git tag -am 'next version' "v${new_major_number}.0.0"
}

is_feat_section_generated() {
  echo "$(generate_unreleased_section)" | pcregrep -M '^### feat$' > /dev/null
}

bump_next_minor() {
  if ! is_feat_section_generated; then
    return 1
  fi

  local major_number="$(get_latest_tag | sed -r 's/'${generate_semver_regex}'/\1/')"
  local minor_number="$(get_latest_tag | sed -r 's/'${generate_semver_regex}'/\2/')"
  local new_minor_number="$(inc $minor_number)"

  git tag -am 'next version' "v${major_number}.${new_minor_number}.0"
}

bump_next_patch() {
  if [ -z "$(generate_unreleased_section)" ]; then
    return 0
  fi

  local patch_number="$(get_latest_tag | sed -r 's/'${generate_semver_regex}'/\3/')"
  local version_without_patch="$(get_latest_tag | sed -r 's/'${generate_semver_regex}'/\1.\2/')"
  local new_patch_number="$(inc $patch_number)"

  git tag -am 'next version' "v${version_without_patch}.${new_patch_number}"
}

bump_next_version() {
  bump_next_major \
  || bump_next_minor \
  || bump_next_patch
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

build_image() {
  local image_id=$(docker build -q - << EOF
FROM alpine:latest as base
RUN \
  --mount=type=cache,target=/var/cache/apk \
  apk update

FROM base as dependencies
RUN \
  --mount=type=cache,target=/var/cache/apk \
  apk add bash git pcre-tools

FROM dependencies as prepare_volume
WORKDIR /root
RUN mkdir -p \
  current_directory \
  script_directory
VOLUME /root/current_directory
VOLUME /root/script_directory

FROM prepare_volume
WORKDIR /root/current_directory
# To ensure identical content create different images allowing test to be run in parallel
LABEL $(print_random_small_string)
EOF
  )

  echo $image_id
}

run_container() {
  local image_id=$1

  shift

  docker run \
    --init --rm \
    -v "$(get_current_directory)":/root/current_directory \
    -v "$(get_script_directory)":/root/script_directory \
    $image_id \
    /bin/ash -c \
    "/root/script_directory/generate.sh "$@" --no-docker" \
  ;  local exit_code=$? \
  && remove_image $image_id \
  && exit $exit_code
}

remove_image() {
  local image_id=$1

  docker image rm $image_id >/dev/null
}

is_no_docker_option_missing() {
  while [ ! -z "$1" ]; do
    if [ "$1" = '-n' ] || [ "$1" = '--no-docker' ];then
      return 1
    fi

    shift
  done
}

run_in_container() {
  is_no_docker_option_missing "$@" \
  && local image_id \
  && image_id=$(build_image) \
  && run_container $image_id "$@"
}

run_locally() {
  parse_arguments "$@" \
  && change_current_directory "$git_repository_directory" \
  && ensure_targeting_git_repository \
  && ensure_there_are_commits \
  && ensure_there_are_no_pending_changes \
  && ensure_there_are_at_least_one_conventional_commit \
  && bump_version_if_asked \
  && output_changelog
}
