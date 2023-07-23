#!/bin/bash -eux

cd "$(dirname "${0}")"

TMPDIR="$(mktemp --directory --tmpdir=..)"
SSH_CONFIG_DIR=~/.ssh/code
mkdir -p $SSH_CONFIG_DIR

cleanup () {
  rm -rf "$TMPDIR" "$SSH_CONFIG_DIR"
}
trap cleanup EXIT

ssh-keygen -t rsa -C "" -N "" -f "${TMPDIR}/id_rsa" > /dev/null

USER=ec2-user
INSTANCE_ID=$(aws ec2 describe-instances --filter "Name=tag:Name,Values=code" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text)
AVAILABILITY_ZONE=$(aws ec2 describe-instances --filter "Name=tag:Name,Values=code" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].Placement.AvailabilityZone" --output text)

if [[ ${INSTANCE_ID:-None} = None || ${AVAILABILITY_ZONE:-None} = None ]]; then
  echo "Error: There is a probrem with a server" >&2
  exit 1
fi

aws ec2-instance-connect send-ssh-public-key \
    --availability-zone "${AVAILABILITY_ZONE}" \
    --instance-id "${INSTANCE_ID}" \
    --instance-os-user "${USER}" \
    --ssh-public-key "file://${TMPDIR}/id_rsa.pub" > /dev/null; 


cat << EOF > ${SSH_CONFIG_DIR}/config
Host code
  ProxyCommand aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p
  Hostname ${INSTANCE_ID}
  User ${USER}
  IdentityFile ${SSH_CONFIG_DIR}/key/id_rsa
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
EOF
cp "${TMPDIR}/id_rsa" ${SSH_CONFIG_DIR}/key

echo "Success: Complete pushing SSH public key to EC2 and push temporary setting to ssh config file"

echo "Info: Please connect to the EC2 in 60 seconds"
sleep 60
echo "Info: SSH key has expired"