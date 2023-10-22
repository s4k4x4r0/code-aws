#!/bin/bash

set -euxo pipefail

if [[ $# -ne 3 ]]; then
  echo "%0 USER HOST PORT" >&2
  exit 1
fi

USER=$1
HOST=$2
PORT=$3

cd "$(dirname "${0}")"

TMPDIR="$(mktemp --directory --tmpdir=..)"
SSH_CONFIG_DIR=~/.ssh/code_aws
mkdir -p "${SSH_CONFIG_DIR}"/key

cleanup () {
  rm -rf "$TMPDIR"
  echo -n "" > "${SSH_CONFIG_DIR}"/key/id_rsa
}
trap cleanup EXIT

ssh-keygen -t rsa -C "" -N "" -f "${TMPDIR}/id_rsa" > /dev/null

INSTANCE_ID=$(aws ec2 describe-instances --filter "Name=tag:Name,Values=${HOST}" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text)
AVAILABILITY_ZONE=$(aws ec2 describe-instances --filter "Name=tag:Name,Values=${HOST}" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].Placement.AvailabilityZone" --output text)

if [[ ${INSTANCE_ID:-None} = None || ${AVAILABILITY_ZONE:-None} = None ]]; then
  echo "Error: There is a probrem with a server" >&2
  exit 1
fi

aws ec2-instance-connect send-ssh-public-key \
    --availability-zone "${AVAILABILITY_ZONE}" \
    --instance-id "${INSTANCE_ID}" \
    --instance-os-user "${USER}" \
    --ssh-public-key "file://${TMPDIR}/id_rsa.pub" > /dev/null; 

cp -f "${TMPDIR}/id_rsa" "${SSH_CONFIG_DIR}/key"

aws ssm start-session --target "${INSTANCE_ID}" --document-name AWS-StartSSHSession --parameters portNumber="${PORT}"


