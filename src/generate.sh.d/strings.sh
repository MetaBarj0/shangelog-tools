#!/bin/sh

generate_error_cannot_bind_git_repository() {
  echo 'Error: cannot bind to a valid git repository'
}

generate_error_no_commits() {
  echo 'Error: the git repository does not contain any commit'
}

generate_error_pending_changes() {
  cat << EOF
Error: there are pending changes in the repository. Commit, discard or stash
them before going any further.
EOF
}

generate_error_no_conventional_commit_found() {
  echo 'Error: no conventional commit found to generate the change log'
}

generate_error_bump_version_not_semver() {
  echo 'Error: initial version value must follow the SemVer convention.'
}

generate_conventional_commit_type_regex() {
  echo 'fix|feat|build|chore|ci|docs|style|refactor|perf|test|revert'
}

generate_conventional_commit_scope_title_regex() {
  echo '(\(.+\))?!?: ([^ ].*)'
}

generate_conventional_breaking_commit_scope_title_regex() {
  echo '(\(.+\))?!: ([^ ].*)'
}

generate_semver_regex() {
  echo '^v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-((0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(\.(0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(\+([0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*))?$'
}

generate_changelog_header() {
  cat << EOF
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
EOF
}

generate_help() {
  cat << EOF
usage: generate.sh [-h | --help] [-b | --bump-version]
                  [-i | --initial-version] [-r | --git-repository]
                  [-n | --no-docker]

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
      The created annotated tag points on a non conventional commit titled
      'bump version' that track a 'CHANGELOG.md' file containing the changelog
      that is also output on stdout.

  -i version | --initial-version=version

      The initial version to set when using -b or --bump-version on a git
      repository that does not have any SemVer annotated tag yet.

  -r directory | --git-repository=directory

      The git repository to target. Useful when the generate.sh script is not
      within a git repository or the current directory is not the git directory
      you want to generate a changelog from.

  -n | --no-docker

      Do not invoke this script within a docker container. It is useful if you
      want to run it on a GNU environment because this script relies heavily on
      GNU tools.
      Do note that you need to have following tools accessible on your machine
      for generate.sh to work properly:
      - git (of course...)
      - a ssh client (for instance open ssh client)
      - pcre grep (a grep on steroid supporting PCRE)
      - bc (the basic calculator)
      - a basic POSIX compliant shell (sh, ash, dash). bash is OK too but not
        required for generate.sh to work.
      By design, this tool has been thought to be run on any platform that
      supports docker container execution. If this option is not specified, an
      image is built and a container is run using it. At the end of the
      invocation, everything is removed (but the build cache, for obvious
      performance reasons) as if this script was run on the host machine.
      The image is based on alpine:edge.

Examples:

  Given you are in the generate.sh directory:

    ./generate.sh will print the changelog on the standard output.

    ./generate.sh --no-docker executes 'generate.sh' directly on the host
    machine and will print the changelog on the standard output.
    Note that for this to work, the host machine must have required GNU tools
    installed. See the '-n' or '--no-docker' option documentation for more
    details.

    ./generate.sh -b will print the changelog on the standard output and bump
    the currently unreleased changes on the respository. Bumping the version
    means creating an annotated tag at the tip of the current branch. If this
    is the first time you bump the version and you do not specify the
    --initial-version option, v0.1.0 will be used by default. Note that this
    new bump version commit will be pushed on origin remote.

    ./generate.sh -b -i v1.0.0 will print the changelog on the standard output
    and bump the currently unreleased changes on the respository to the
    'v1.0.0' version. You MUST use a SemVer compliant version for the '-i'
    option otherwise the script exits with an error.
EOF
}
