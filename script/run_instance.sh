#!/bin/bash -eux

set -eux

print_usage() {
  echo "USAGE: ${0} [-r] NAME_TAG" >&2
  echo "USAGE: -r: If an instance with a matching Name tag does not exist, a new server will be run" >&2
}

while getopts 'r' OPT; do
  case "${OPT}" in
  r) ENABLE_RUN=1 ;;
  ?)
    print_usage
    exit 1
    ;;
  esac
done

shift $((OPTIND - 1))

if [[ $# -ne 1 ]]; then
  print_usage
  exit 1
fi

NAME_TAG="${1}"

cd "$(dirname "${0}")"

INSTANCE_ID="$(aws ec2 describe-instances --filter "Name=tag:Name,Values=${NAME_TAG}" "Name=instance-state-name,Values=pending,running,stopped" --query "Reservations[0].Instances[0].InstanceId" --output text)"

if [[ ${INSTANCE_ID} = "None" ]]; then
  if [[ ${ENABLE_RUN:=0} -eq 1 ]]; then
    LAUNCH_TEMPLATE_NAME="$(aws ec2 describe-launch-templates | jq -r '.LaunchTemplates[] | select(.LaunchTemplateName | startswith("CodeServerTemplate")).LaunchTemplateName')"
    TAG_SPECIFICATIONS=""
    for RT in instance volume network-interface; do
      TAG_SPECIFICATIONS="${TAG_SPECIFICATIONS}{\"ResourceType\":\"${RT}\",\"Tags\":[{\"Key\":\"Name\",\"Value\":\"${NAME_TAG}\"}]}"
    done
    TAG_SPECIFICATIONS="$(jq -csr '.' <<< "${TAG_SPECIFICATIONS}")"
    if aws ec2 run-instances --launch-template "LaunchTemplateName=${LAUNCH_TEMPLATE_NAME}" --tag-specifications "${TAG_SPECIFICATIONS}" >/dev/null; then
      echo "INFO: A new server has been run"
    fi
  else
    echo "WARNING: Instance which Name tag is ${NAME_TAG} is not found"
    echo "WARNING: if you start a new server, add -r option"
  fi
else
  echo "INFO: An instance with Name tag ${NAME_TAG} exist"
  if aws ec2 start-instances --instance-ids "${INSTANCE_ID}" >/dev/null; then
    echo "INFO: successfully started the instance"
  fi
fi
