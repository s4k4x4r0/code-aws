#!/bin/bash -eux

if [[ $# -ne 3 ]]; then
  echo "%0 USER HOST PORT" >&2
  exit 1
fi

USER="$1"
HOST="$2"
PORT="$3"

cd "$(dirname "${0}")"

SSH_CONFIG_DIR=~/.ssh/code_aws
mkdir -p $SSH_CONFIG_DIR/key

cat << EOF >> "${SSH_CONFIG_DIR}/config"
Host ${HOST}
  ProxyCommand ${PWD}/start-ssh-proxy.sh %r %h %p
  User ${USER}
  Hostname ${HOST}
  Port ${PORT}
  IdentityFile ${SSH_CONFIG_DIR}/key/id_rsa
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
EOF

echo -n "" > ${SSH_CONFIG_DIR}/key/id_rsa
chmod 0600 ${SSH_CONFIG_DIR}/key/id_rsa