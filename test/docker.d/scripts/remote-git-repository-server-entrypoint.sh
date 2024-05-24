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

  sshd_pid=$!
}

run_live_loop() {
  while true; do
    sleep 1
  done
}

shutdown() {
  echo Terminating remote git repository server gracefully

  kill ${sshd_pid}

  exit $?
}

setup_signal_handling() {
  trap shutdown SIGHUP SIGINT SIGQUIT SIGTERM
}

main() {
  setup_signal_handling \
  && setup_ssh_server \
  && start_ssh_server \
  && run_live_loop
}

main
