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