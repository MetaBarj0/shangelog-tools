#!/bin/sh

get_script_dir() {
  local script_dirname="$(dirname "$0")"
  cd "$script_dirname" >/dev/null 2>&1
  pwd -P
  cd - >/dev/null 2>&1
}

load_functions() {
  local script_dir="$(get_script_dir)"

  source "${script_dir}/generate.sh.d/functions.sh"
  load_strings "${script_dir}"
}

parse_arguments() {
  initialize_argument_default_values

  local valid_args \
  && valid_args="$(getopt -q -o br:i:hn --long bump-version,git-repository:,initial-version:,help,no-docker -- $@)"

  if [ $? -ne 0 ]; then
    show_help 1
  fi

  eval set -- "$valid_args"

  while true; do
    case "$1" in
      -b | --bump-version)
        bump_version_asked='true'
        shift
        ;;
      -r | --git-repository)
        git_repository_directory="$2"
        shift 2
        ;;
      -i | --initial-version)
        initial_version="$2"
        shift 2
        ;;
      -h | --help)
        show_help
        shift
        break
        ;;
      -n | --no-docker)
        no_docker_asked='true'
        shift
        break
        ;;
      --)
        shift
        break
        ;;
    esac
  done

  ensure_arguments_are_valid
}

run() {
  if [ "$no_docker_asked" = 'true' ]; then
    run_locally
  else
    run_in_container
  fi
}

main() {
  load_functions \
  && parse_arguments "$@" \
  && run "$@"
}

main $@
