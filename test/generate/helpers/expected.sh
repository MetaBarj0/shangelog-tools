#!/bin/sh

merge_tests_exepcted_output_pattern() {
  cat << EOF
^## \[v0\.2\.0\]$

^### fix$

^- another urgent fix ${generate_sha1_pattern}$

^## \[v0\.1\.0\]$

^### fix$

^- urgent fix ${generate_sha1_pattern}$

^### feat$

^- a very fancy feature ${generate_sha1_pattern}$
EOF
}

empty_commit_incorrect_pattern() {
  cat << EOF
^## \[Unreleased\]$

^### feat$

^- top commit ${generate_sha1_pattern}$

^### chore$

^- under the top commit ${generate_sha1_pattern}$

^## \[v0\.2\.0\]$

^### feat$

^- top commit \[\]$

^## \[v0\.1\.0\]$

^### feat$

^- top commit \[\]$
EOF
}
