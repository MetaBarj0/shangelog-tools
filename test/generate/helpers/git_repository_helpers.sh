#!/bin/sh

create_git_repository() {
  git init > /dev/null 2>&1

  git config user.email "bats@test.suite"
  git config user.name "bats"
}

create_git_repository_with_remote() {
  create_git_repository
  setup_repository_remote
}

commit_with_message() {
  local message="$1"

  echo "$message" >> messages

  git add messages > /dev/null 2>&1
  git commit -m "$message" > /dev/null 2>&1
}

commit_with_message_and_push_to_remote() {
  commit_with_message "$1"
  push_to_remote
}

create_git_repository_and_cd_in() {
  mkdir -p "$1"
  cd "$1"
  create_git_repository
}

create_annotated_tag() {
  local version="$1"

  git tag -am "annotated tag: $version" "$version"
}

switch_to_branch() {
  local branch_name="$1"

  if ! git rev-parse --verify "$branch_name" >/dev/null 2>&1; then
    git checkout -b "$branch_name"
  else
    git switch "$branch_name"
  fi
}

merge_no_ff() {
  local current_branch="$(git symbolic-ref --short HEAD)"
  local merge_branch="$1"

  git merge --no-ff --commit --no-edit "$merge_branch"
}

setup_repository_remote() {
  local remote_dir="${BATS_TEST_TMPDIR}/remote"

  mkdir "${remote_dir}"

  cd "${remote_dir}" >/dev/null 2>&1

  git init --bare >/dev/null 2>&1

  cd - >/dev/null 2>&1

  git remote add origin "${remote_dir}" >/dev/null 2>&1
}

push_to_remote() {
  git push -u origin master >/dev/null 2>&1
}
