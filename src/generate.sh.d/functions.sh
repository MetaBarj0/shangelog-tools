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

get_repository_directory() {
  if [ -z "${git_repository_directory}" ]; then
    local result="$(get_current_directory)"
  else
    if [ -z "${REPOSITORY_DIRECTORY_OVERRIDE}" ]; then
      local result="${git_repository_directory}"
    else
      local result="${REPOSITORY_DIRECTORY_OVERRIDE}"
    fi
  fi

  echo "$result"
}

get_ssh_secret_key_path() {
  # TODO: try to export function instead of variables
  if [ -z "${SSH_SECRET_KEY_PATH_OVERRIDE}" ]; then
    # TODO: check outside of test env, add option to customize it
    cd ~/.ssh >/dev/null
    echo "$(pwd -P)/id_rsa"
    cd - >/dev/null
  else
    echo "${SSH_SECRET_KEY_PATH_OVERRIDE}"
  fi
}

get_ssh_public_key_path() {
  if [ -z "${SSH_PUBLIC_KEY_PATH_OVERRIDE}" ]; then
    # TODO: customize key path
    cd ~/.ssh >/dev/null
    echo "$(pwd -P)/id_rsa.pub"
    cd - >/dev/null
  else
    echo "${SSH_PUBLIC_KEY_PATH_OVERRIDE}"
  fi
}

get_ssh_agent_sock_path() {
  if [ -z "${SSH_AGENT_SOCK_PATH_OVERRIDE}" ]; then
    echo "${SSH_AUTH_SOCK}"
  else
    echo "${SSH_AGENT_SOCK_PATH_OVERRIDE}"
  fi
}

load_strings() {
  local script_dir="$1"

  . "${script_dir}/generate.sh.d/strings.sh"
}

ensure_arguments_are_valid() {
  echo "$initial_version" \
  | pcregrep "$(generate_semver_regex)" > /dev/null \
  || ( local exit_code=$? \
       && echo $(generate_error_bump_version_not_semver) >&2 \
       && exit $exit_code )
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

ensure_current_directory_is_git_repository() {
  git status > /dev/null
}

ensure_script_is_within_git_repository() {
  if [ $? -ne 0 ]; then
    local script_dirname="$(dirname "$0")"
    cd "$script_dirname" >/dev/null
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
    local conventional_commit_header="^(${commit_type})$(generate_conventional_commit_scope_title_regex)"
    local sha1="$(echo ${commit_sha1} | cut -c 1-8)"
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
    "^($(generate_conventional_commit_type_regex))$(generate_conventional_commit_scope_title_regex)" \
    "${end_rev}"
}

is_there_any_conventional_commit() {
  [ $(git rev-list \
        --count -E -i --grep \
        "^($(generate_conventional_commit_type_regex))$(generate_conventional_commit_scope_title_regex)" \
        "$(git branch --show-current)") -gt 0 ]
}

list_changelog_compliant_commits_from_rev_to_tip() {
  local rev="$1"

  [ ! -z "$rev" ] \
  && local rev_option \
  && rev_option="^${rev}" \
  || rev_option="$(git branch --show-current)"

  git rev-list \
    -E -i --grep \
    "^($(generate_conventional_commit_type_regex))$(generate_conventional_commit_scope_title_regex)" \
    HEAD "${rev_option}"
}

list_changelog_compliant_commits_from_and_up_to() {
  local begin_rev="$1"
  local end_rev="$2"

  git rev-list \
    -E -i --grep \
    "^($(generate_conventional_commit_type_regex))$(generate_conventional_commit_scope_title_regex)" \
    "${begin_rev}" ^"${end_rev}"
}

output_section_header() {
  local header_name="$1"

  echo "
## [$1]"
}

change_separator_for_read() {
  local string="$1"
  local separator="$2"

  echo "${string}" \
  | sed "s/${separator}/\n/g"
}

output_all_commit_type_paragraphs() {
  local changelog_compliant_commits="$1"
  local commit_types="$(change_separator_for_read "$(generate_conventional_commit_type_regex)" '|')"

  while read commit_type; do
    local commit_type_content="$(generate_commit_type_content_for $commit_type "${changelog_compliant_commits}")"

    if [ -z "${commit_type_content}" ]; then
      continue
    fi

    local commit_type_header="$(generate_commit_type_header $commit_type)"

    eval "$(cat << EOF_eval
local ${commit_type}_paragraph=\$(cat << EOF
\${commit_type_header}

\${commit_type_content}
EOF
)
EOF_eval
    )"
  done << EOF_while
${commit_types}
EOF_while

  while read commit_type; do
    eval "local paragraph=\"\${${commit_type}_paragraph}\""

    [ -z "${paragraph}" ] && continue

    echo "
${paragraph}"
  done << EOF
${commit_types}
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

  if [ -z "$lower_tag" ]; then
    local commits="$(list_changelog_compliant_commits_reachable_from $upper_tag)"
  else
    local commits="$(list_changelog_compliant_commits_from_and_up_to $upper_tag $lower_tag)"
  fi

  [ -z "$commits" ] && return 0

  output_section "${upper_tag}" "${commits}"

  local next_tags="$(echo "$1" | sed '1d')"
  local next_lower_tag="$(echo "$next_tags" | sed '1d' | head -n 1)"

  [ ! -z "$lower_tag" ] \
  && generate_versioned_section "$next_tags" "$next_lower_tag"

  return 0
}

get_all_sorted_annotated_tags() {
  git for-each-ref \
    --format='%(objecttype) %(refname:short)' \
    --sort='v:refname' \
  | grep tag \
  | sed 's/^tag //'
}

get_all_semver_tags_from_newest_to_oldest() {
  get_all_sorted_annotated_tags \
  | pcregrep "$(generate_semver_regex)" \
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

  echo "${generate_help}"

  exit $exit_code
}

is_repository_already_versionned() {
  [ $(get_all_semver_tags_from_newest_to_oldest | wc -l) -gt 0 ]
}

bump_initial_version() {
  git tag -am 'initial version' "${initial_version}"

  echo "${initial_version}"
}

show_commit_body() {
  local commit_sha1="$1"

  git show -s --pretty='format:%b' $commit_sha1
}

is_it_breaking_commit_summary() {
  local commit_summary="$1"
  local breaking_commit_summary_pattern="($(generate_conventional_commit_type_regex))$(generate_conventional_breaking_commit_scope_title_regex)"

  echo "$commit_summary" | grep -E "${breaking_commit_summary_pattern}" >/dev/null
}

extract_footer() {
  local body="$(echo "$1" | tac)"

  while read line; do
    if [ -z "$line" ]; then
      break
    fi

    local footer="$footer"$'\n'"$line"
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

  local major_number="$(get_latest_tag | sed -r 's/'$(generate_semver_regex)'/\1/')"
  local new_major_number="$(inc $major_number)"
  local semver="v${new_major_number}.0.0"

  git tag -am 'next version' "${semver}"

  echo "${semver}"
}

is_feat_section_generated() {
  echo "$(generate_unreleased_section)" | pcregrep -M '^### feat$' > /dev/null
}

bump_next_minor() {
  if ! is_feat_section_generated; then
    return 1
  fi

  local major_number="$(get_latest_tag | sed -r 's/'$(generate_semver_regex)'/\1/')"
  local minor_number="$(get_latest_tag | sed -r 's/'$(generate_semver_regex)'/\2/')"
  local new_minor_number="$(inc $minor_number)"
  local semver="v${major_number}.${new_minor_number}.0"

  git tag -am 'next version' "${semver}"

  echo "${semver}"
}

bump_next_patch() {
  if [ -z "$(generate_unreleased_section)" ]; then
    return 0
  fi

  local patch_number="$(get_latest_tag | sed -r 's/'$(generate_semver_regex)'/\3/')"
  local version_without_patch="$(get_latest_tag | sed -r 's/'$(generate_semver_regex)'/\1.\2/')"
  local new_patch_number="$(inc $patch_number)"
  local semver="v${version_without_patch}.${new_patch_number}"

  git tag -am 'next version' "${semver}"

  echo "${semver}"
}

bump_next_version() {
  local new_version \
  && new_version="$(bump_next_major)" \
  || new_version="$(bump_next_minor)" \
  || new_version="$(bump_next_patch)"

  echo "${new_version}"
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
    echo "$(generate_error_cannot_bind_git_repository)" >&2
    exit 1
  fi
}

ensure_there_are_commits() {
  local commit_count=$(git rev-list --all | wc -l)
  if [ $commit_count -lt 1 ]; then
    echo "$(generate_error_no_commits)" >&2
    exit 1
  fi
}

ensure_there_are_no_pending_changes() {
  local pending_changes="$(git status --porcelain=v1 -uno)"

  if [ ! -z "$pending_changes" ]; then
    echo "$(generate_error_pending_changes)" >&2

    exit 1
  fi
}

ensure_there_are_at_least_one_conventional_commit() {
  if ! is_there_any_conventional_commit; then
    echo "$(generate_error_no_conventional_commit_found)" >&2
    exit 1
  fi
}

pre_bump_version_if_asked() {
  if [ ! "$bump_version_asked" = 'true' ]; then
    return 0
  fi

  if ! is_repository_already_versionned; then
    echo "$(bump_initial_version)"

    return $?
  fi

  echo "$(bump_next_version)"
}

repository_has_remotes() {
  local remotes_reported="$(git remote -v)"

  [ ! -z "${remotes_reported}" ]
}

get_remote_host() {
  git remote get-url origin \
    | sed -r 's/^git@//' \
    | sed -r 's/:.+$//'
}

learn_remote_ssh_host() {
  ssh-keyscan -t rsa "$(get_remote_host)" >/root/.ssh/known_hosts
}

re_bump_version() {
  local version="$1"
  local changelog="$2"

  git tag -d "${version}" >/dev/null
  echo "${changelog}" > CHANGELOG.md
  git add CHANGELOG.md
  git commit -m 'bump version' >/dev/null
  git tag -am "bump version: ${version}" "${version}"

  if repository_has_remotes; then
    learn_remote_ssh_host \
    && git push origin >/dev/null \
    && git push origin --tags >/dev/null
  fi
}

bump_version_if_asked() {
  local new_version="$1"
  local changelog="$2"

  if [ ! -z "${new_version}" ]; then
    re_bump_version "${new_version}" "${changelog}"
  fi
}

output_changelog() {
  local new_version \
  && new_version="$(pre_bump_version_if_asked)" \
  && local sections \
  && sections="$(generate_sections)" \
  && local changelog \
  && changelog="$(cat << EOF
$(generate_changelog_header)
${sections}
EOF
  )" \
  && bump_version_if_asked "${new_version}" "${changelog}" \
  && echo "${changelog}"
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
  apk add git pcre-tools openssh-client bc

FROM dependencies as prepare_volume
WORKDIR /root
RUN mkdir -p \
  current_directory \
  script_directory \
  repository_directory
VOLUME /root/current_directory
VOLUME /root/script_directory
VOLUME /root/repository_directory

FROM prepare_volume
WORKDIR /root/current_directory
# To ensure identical content create different images allowing test to be run in parallel
LABEL $(print_random_small_string)
EOF
  )

  echo $image_id
}

craft_container_commands_with() {
  cat << EOF
ssh-keyscan \
  -t rsa \
  localhost \
  > /root/.ssh/known_hosts

/root/script_directory/generate.sh \
  $@ \
  --git-repository /root/repository_directory \
  --no-docker
EOF
}

run_container() {
  local image_id=$1

  shift

  docker run \
    --init --rm \
    --network=host \
    -e GIT_AUTHOR_NAME="$(git config user.name)" \
    -e GIT_COMMITTER_NAME="$(git config user.name)" \
    -e GIT_AUTHOR_EMAIL="$(git config user.email)" \
    -e GIT_COMMITTER_EMAIL="$(git config user.email)" \
    -e SSH_AUTH_SOCK=/root/.ssh/agent-sock \
    -v "$(get_current_directory)":/root/current_directory \
    -v "$(get_script_directory)":/root/script_directory \
    -v "$(get_repository_directory)":/root/repository_directory \
    -v "$(get_ssh_secret_key_path)":/root/.ssh/id_rsa:ro \
    -v "$(get_ssh_public_key_path)":/root/.ssh/id_rsa.pub:ro \
    -v "$(get_ssh_agent_sock_path)":/root/.ssh/agent-sock:ro \
    $image_id \
    /bin/ash \
    '-c' \
    "$(craft_container_commands_with "$@")" \
  ; local exit_code=$? \
  && remove_image $image_id \
  && return $exit_code
}

remove_image() {
  local image_id=$1

  docker image rm $image_id >/dev/null
}

# EXPLAIN
# specific substitute to getopt that is not the same on all platforms
# I need to evaluate this option to know if I have to show the help at once
# before getting into a container.
show_help_if_required() {
  while [ ! -z "$1" ]; do
    if [ "$1" = '-h' ] || [ "$1" = '--help' ];then
      show_help

      exit $?
    fi

    shift
  done
}

# EXPLAIN
# specific substitute to getopt that is not the same on all platforms
# I need to evaluate this option to know if I have to run a container
is_no_docker_option_missing() {
  while [ ! -z "$1" ]; do
    if [ "$1" = '-n' ] || [ "$1" = '--no-docker' ];then
      return 1
    fi

    shift
  done
}

# EXPLAIN
# specific substitute to getopt that is not the same on all platforms
# I need to evaluate this option to know how to bind volumes on the container I
# need to run
parse_git_repository_option() {
  while [ ! -z "$1" ]; do
    if [ "$1" = '-r' ] || [ "$1" = '--git-repository' ];then
      shift

      cd "$1" >/dev/null
      git_repository_directory="$(pwd -P)"
      cd - >/dev/null

      return 0
    fi

    shift
  done
}

run_in_container() {
  show_help_if_required "$@" \
  && is_no_docker_option_missing "$@" \
  && parse_git_repository_option "$@" \
  && local image_id \
  && image_id=$(build_image) \
  && run_container $image_id "$@"
}

run_locally() {
  parse_arguments "$@" \
  && change_current_directory "${git_repository_directory}" \
  && ensure_targeting_git_repository \
  && ensure_there_are_commits \
  && ensure_there_are_no_pending_changes \
  && ensure_there_are_at_least_one_conventional_commit \
  && output_changelog
}
