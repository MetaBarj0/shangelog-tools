#!/bin/sh

pause_test() {
  echo "Current test tmpdir: $BATS_TEST_TMPDIR" >&3
  read -n1 -s
}

get_line_count() {
  local output="$1"
  local output_line_count=0
  while read out; do
    output_line_count=$(bc << EOF_bc
$output_line_count + 1
EOF_bc
    )
  done << EOF
  $output
EOF

  echo $output_line_count
}

print_test() {
  echo "<<<$@>>>" >&3
}

generate_no_docker() {
  generate.sh "$@" --no-docker
}

generate_in_docker() {
  generate.sh "$@"
}

override_test_directory_bind_mount_with() {
  local current_working_directory="$1"

  echo "$current_working_directory" \
  | sed -E "s%${BATS_TMPDIR}%${HOST_TEST_OUTPUT_DIR}%"
}

override_script_directory_for_bind_mount_with() {
  local script_directory="$(override_test_directory_bind_mount_with "$1")"

  export SCRIPT_DIRECTORY_OVERRIDE="${script_directory}"
}

override_current_directory_for_bind_mount_with() {
  local current_directory="$(override_test_directory_bind_mount_with "$1")"

  export CURRENT_DIRECTORY_OVERRIDE="${current_directory}"
}
