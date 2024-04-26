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
