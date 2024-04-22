#!/bin/sh

ensure_match() {
  local value="$1"
  local pattern="$2"

  echo "$value" | pcregrep -M "$pattern"
}
