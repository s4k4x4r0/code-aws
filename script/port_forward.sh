#!/bin/bash -eux

set -eux

cd "$(dirname "${0}")"

print_usage() {
  echo "$0 [-i <INSTANCE_ID>] -l <LOCAL_PORT> -r <REMOTE_PORT>" >&2
  echo "INSTANCE_ID: (default) ID of EC2 instance name-tagged with 'code'" >&2
}

while getopts 'i:l:r:' opt; do
  case "$opt" in
  i) INSTANCE_ID=$OPTARG ;;
  l) LOCAL_PORT=$OPTARG ;;
  r) REMOTE_PORT=$OPTARG ;;
  ?)
    print_usage
    exit 1
    ;;
  esac
done

if [[ -z ${INSTANCE_ID:-} ]]; then
  INSTANCE_ID=$(aws ec2 describe-instances --filter "Name=tag:Name,Values=code" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text)
fi

if [[ -z ${LOCAL_PORT:-} ]]; then
  LOCAL_PORT=8080
fi

if [[ -z ${REMOTE_PORT:-} ]]; then
  REMOTE_PORT=8080
fi

if [[ ! ${INSTANCE_ID:-} =~ ^i-[a-f0-9]+$ || ! ${LOCAL_PORT:-} =~ ^[1-9][0-9]*$ || ! ${REMOTE_PORT:-} =~ ^[1-9][0-9]*$ ]]; then
  print_usage
  exit 1
fi

aws ssm start-session \
  --target "$INSTANCE_ID" \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["'"${REMOTE_PORT}"'"], "localPortNumber":["'"${LOCAL_PORT}"'"]}'
