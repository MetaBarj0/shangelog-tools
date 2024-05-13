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
  git describe --abbrev=0 2>/dev/null
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

generate_unreleased_section() {
  local latest_tag="$(get_latest_tag)"

  local commits="$(list_changelog_compliant_commits_from_rev_to_tip ${latest_tag})"

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

get_all_semver_tags_from_newest_to_oldest() {
  for tag in $(git tag); do
    if [ "$(git cat-file -t $tag)" = "tag" ]; then
      echo $tag
    fi
  done \
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
  cat << EOF
usage: generate.sh [-h | --help] [-b | --bump-version]
                   [-i | --initial-version] [-r | --git-repository]

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

Examples:

  Given you're in the generate.sh directory:

    ./generate.sh will print the changelog on the standard output.

    ./generate.sh -b will print the changelog on the standard output and bump
    the currently unreleased changes on the respository. Bumping the version
    means creating an annotated tag at the tip of the current branch. If this
    is the first time you bump the version and you do not specify the
    --initial-version option, v0.1.0 will be used by default.
EOF

  exit 0
}
