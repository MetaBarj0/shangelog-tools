#!/bin/sh

setup_git_test_user_info_for_repository() {
  git config user.email "bats@test.suite"
  git config user.name "bats"
}

create_git_repository() {
  git init > /dev/null 2>&1

  setup_git_test_user_info_for_repository
}

create_remote_git_repository_and_clone_it() {
  local repository_name=remote
  local repository_path=user/"${repository_name}".git

  docker exec \
    -u git \
    shangelog-tools-remote-git-repository-server \
    ./create-bare-repository-in.sh "${repository_path}"

  git clone \
    git@shangelog-tools-remote-git-repository-server:"${repository_path}" \
    >/dev/null 2>&1

  cd "${repository_name}"

  setup_git_test_user_info_for_repository
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

push_to_remote() {
  git push -u origin master >/dev/null 2>&1
}
