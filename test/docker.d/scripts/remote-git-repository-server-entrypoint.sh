#!/bin/sh

amend_sshd_config() {
  cat >>/etc/ssh/sshd_config << EOF
PasswordAuthentication no
EOF
}

generate_server_keys() {
  ssh-keygen -A >/dev/null
}

setup_ssh_server() {
  amend_sshd_config \
  && generate_server_keys
}

start_ssh_server() {
  $(which sshd) -D -e &
}

run_live_loop() {
  while true; do
    sleep 1
  done
}

main() {
  setup_ssh_server \
  && start_ssh_server \
  && run_live_loop
}

main
