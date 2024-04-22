#!/bin/sh

generate_error_not_git_repository=\
'Error: this script must be run within a git repository'

generate_error_no_commits=\
'Error: the git repository does not contain any commit'

generate_error_pending_changes=\
"$(cat << EOF
Error: there are pending changes in the repository. Commit, discard or stash
them before going any further.
EOF
)"

generate_error_no_conventional_commit_found=\
'Error: no conventional commit found to generate the change log'

generate_conventional_commit_type_regex=\
'chore|feat'

generate_changelog_header=\
"$(cat << EOF
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
EOF
)"
