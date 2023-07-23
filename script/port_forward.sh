#!/bin/bash -eux

set -eux

cd "$(dirname "${0}")"

print_usage() {
  echo "$0 [-i <instance_id>] -l <local_port> -r <remote_port>" >&2
  echo "instance_id: (default) ID of EC2 instance name-tagged with 'code'" >&2
}

while getopts 'i:l:r:' opt; do
  case "$opt" in
  i) instance_id=$OPTARG ;;
  l) local_port=$OPTARG ;;
  r) remote_port=$OPTARG ;;
  ?)
    print_usage
    exit 1
    ;;
  esac
done

if [[ -z ${instance_id:-} ]]; then
  instance_id=$(aws ec2 describe-instances --filter "Name=tag:Name,Values=code" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text)
fi

if [[ -z ${local_port:-} ]]; then
  local_port=8080
fi

if [[ -z ${remote_port:-} ]]; then
  remote_port=8080
fi

if [[ ! ${instance_id:-} =~ ^i-[a-f0-9]+$ || ! ${local_port:-} =~ ^[1-9][0-9]*$ || ! ${remote_port:-} =~ ^[1-9][0-9]*$ ]]; then
  print_usage
  exit 1
fi

aws ssm start-session \
  --target "$instance_id" \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["'"${remote_port}"'"], "localPortNumber":["'"${local_port}"'"]}'
