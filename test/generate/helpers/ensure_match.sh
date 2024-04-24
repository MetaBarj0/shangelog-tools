#!/bin/sh

ensure_match() {
  if [ $# -ne 2 ]; then
    echo 'ensure_match must be called with 2 arguments: <value> <pattern>' >&2
    exit 1
  fi

  local value="$1"
  local pattern="$2"

  echo "$value" | pcregrep -M "$pattern" \
    || (cat << EOF
ensure_match failed
 -> value:   ${value}
===
===
 -> pattern: ${pattern}
EOF
        \ && return 1)
}
