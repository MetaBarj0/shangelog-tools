#!/bin/sh

assert_pcre_match() {
  if [ $# -ne 2 ]; then
    echo 'assert_pcre_match must be called with 2 arguments: <value> <pattern>' >&2
    exit 1
  fi

  local value="$1"
  local pattern="$2"

  assert echo "$value" | pcregrep -M "$pattern" 
}

assert_line_count_equals() {
  local input="$1"
  local expected="$2"

  assert [ $(get_line_count "$input") -eq $expected ]
}

assert_latest_annotated_tag_equals() {
  local expected="$1"

  [ "$(git describe --abbrev=0)" = "$expected" ]
}
