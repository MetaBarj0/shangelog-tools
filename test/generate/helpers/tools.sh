#!/bin/sh

pause_test() {
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
