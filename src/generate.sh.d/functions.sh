#!/bin/sh

load_strings() {
  local script_dir="$1"

  source "${script_dir}/generate.sh.d/strings.sh"
}

initialize_argument_default_values() {
  initial_version=v0.1.0
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

get_latest_tag() {
  git describe --abbrev=0 2>/dev/null
}

list_changelog_compliant_commits_up_to() {
  local end_rev="$1"
  local end_rev_option="$([ ! -z $end_rev ] && echo ${end_rev} || echo '--all')"

  git rev-list \
    -E -i --grep \
    "^(${generate_conventional_commit_type_regex})(\(.+\))?: [^ ].*" \
    "${end_rev_option}"
}

# TODO: refacto conventional commit header pattern
is_there_any_conventional_commit() {
  [ $(git rev-list \
        --count -E -i --grep \
        "^(${generate_conventional_commit_type_regex})(\(.+\))?: [^ ].*" \
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
    "^(${generate_conventional_commit_type_regex})(\(.+\))?: [^ ].*" \
    HEAD "${rev_option}"
}

list_changelog_compliant_commits_from_and_up_to() {
  local begin_rev="$1"
  local end_rev="$2"

  git rev-list \
    -E -i --grep \
    "^(${generate_conventional_commit_type_regex})(\(.+\))?: [^ ].*" \
    "${begin_rev}" "${end_rev}~1"
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

output_section_header() {
  local header_name="$1"

  echo $'\n## ['"$1"']'
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

generate_unreleased_section() {
  local latest_tag="$(get_latest_tag)"

  local commits="$(list_changelog_compliant_commits_from_rev_to_tip ${latest_tag})"

  if [ -z "$commits" ]; then
    return 0
  fi

  initialize_all_commit_type_variables "${commits}"

  output_section_header 'Unreleased'
  output_all_commit_type_paragraphs
}

generate_versioned_sections() {
  local latest_tag="$(get_latest_tag)"

  [ -z "$latest_tag" ] && return 0

  local commits="$(list_changelog_compliant_commits_up_to ${latest_tag})"

  if [ -z "$commits" ]; then
    return 0
  fi

  initialize_all_commit_type_variables "${commits}"

  output_section_header "${latest_tag}"
  output_all_commit_type_paragraphs
}

generate_sections() {
  generate_unreleased_section \
  && generate_versioned_sections \
  || exit $?
}
