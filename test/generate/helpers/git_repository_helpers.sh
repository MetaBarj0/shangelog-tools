#!/bin/sh

create_git_repository() {
  git init > /dev/null 2>&1

  git config user.email "bats@test.suite"
  git config user.name "bats"
}

commit_with_message() {
  local message="$1"

  echo "$message" >> messages

  git add messages > /dev/null 2>&1
  git commit -m "$message" > /dev/null 2>&1
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
