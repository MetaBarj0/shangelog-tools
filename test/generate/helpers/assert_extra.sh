#!/bin/sh

source ./tools.sh

assert_pcre_match() {
  if [ $# -ne 2 ]; then
    echo 'assert_pcre_match must be called with 2 arguments: <value> <pattern>' >&2
    exit 1
  fi

  local value="$1"
  local pattern="$2"

  echo "$value" | pcregrep -M "$pattern" \
    || (cat << EOF
assert_pcre_match failed
 -> value:   ${value}
===
===
 -> pattern: ${pattern}
EOF
        \ && return 1)
}

assert_line_count_equals() {
  local input="$1"
  local expected="$2"

  [ $(get_line_count "$input") -eq $expected ] \
    || (cat << EOF
assert_line_count_equals failed
 -> input:    ${input}
===
===
 -> count:    $(get_line_count $input)
===
===
 -> expected: ${expected}
EOF
     \ && return 1)
}
