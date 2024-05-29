#!/bin/sh

get_script_directory_before_override() {
  local script_dirname="$(dirname "$0")"
  cd "$script_dirname" >/dev/null 2>&1
  pwd -P
  cd - >/dev/null 2>&1
}

load_functions() {
  local script_dir="$(get_script_directory_before_override)"

  source "${script_dir}/generate.sh.d/functions.sh"
  load_strings "${script_dir}"
}

run() {
  if is_no_docker_option_missing "$@"; then
    run_in_container "$@"
  else
    run_locally "$@"
  fi
}

main() {
  load_functions \
  && run "$@"
}

main $@
