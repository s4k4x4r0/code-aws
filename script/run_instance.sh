#!/bin/bash -eux

set -eux

cd "$(dirname "${0}")"

LAUNCH_TEMPLATE_NAME="$(aws ec2 describe-launch-templates | jq -r '.LaunchTemplates[] | select(.LaunchTemplateName | startswith("CodeServerTemplate")).LaunchTemplateName')"

aws ec2 run-instances --launch-template "LaunchTemplateName=${LAUNCH_TEMPLATE_NAME}" > /dev/null

echo "Success: Complete running the server"