#!/bin/sh

git status > /dev/null 2>&1 

if [ $? -ne 0 ]; then
  echo 'Error: this script must be run within a git repository'
  exit 1
fi

commit_count=$(git rev-list --all | wc -l)
if [ $commit_count -lt 1 ]; then
  echo 'Error: the git repository does not contain any commit'
  exit 1
fi

changelog_compliant_commits=\
  $(git rev-list \
      --all -E -i --grep \
      '^(feat|fix|chore|build|ci|test|docs|style|refactor|perf|revert)(\(.+\))?!?: [^ ].*')


if [ -z $changelog_compliant_commits ]; then
  echo 'Error: no suitable commit found to generate the change log'
  exit 1
fi
