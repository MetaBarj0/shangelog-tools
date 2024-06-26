#!/bin/sh

create_git_repository() {
  git init > /dev/null
}

create_remote_git_repository_and_clone_it() {
  local repository_name=remote
  local repository_path=user/"${repository_name}".git

  docker exec \
    -u git \
    shangelog-tools-remote-git-repository-server \
    ./create-bare-repository-in.sh "${repository_path}"

  # At this stage, we're simulating an existing repository thus, we do not have
  # to knwo hosts to clone it. It forces us to scan for host key only when
  # necessary that is at bump version time if asked.
  GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=no' \
  git clone \
    git@localhost:"${repository_path}" \
    >/dev/null

  cd "${repository_name}"
}

commit_with_message() {
  local message="$1"

  echo "$message" >> messages

  git add messages > /dev/null
  git commit -m "$message" > /dev/null
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

  if ! git rev-parse --verify "$branch_name" >/dev/null; then
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
  git push -u origin master >/dev/null
}
