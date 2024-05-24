#!/bin/sh

main() {
  local repository_path="$1"

  cd /home/git

  mkdir -p "${repository_path}"

  cd "${repository_path}"

  git init --bare >/dev/null 2>&1

  chown -R git:git "/home/git/${repository_path}"
}

main "$@"
