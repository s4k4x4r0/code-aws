#!/bin/bash -eux

set -eux

print_usage () {
  echo "$0 [-d]" >&2
  echo "-d: Actually execute a change set"
}

while getopts d option;do
  case $option in
    d) IS_DEPLOYMENT=1;;
    \?) print_usage
        exit 1
  esac
done

cd "$(dirname "${0}")"

TEMPLATE_DIR="../cfn/template"
PARAMETER_DIR="../cfn/parameter"

if [[ ${IS_DEPLOYMENT:-0} -eq 1 ]]; then
  CHANGESET_OPTION=""
else
  CHANGESET_OPTION="--no-execute-changeset"
fi

aws cloudformation deploy \
  --template ${TEMPLATE_DIR}/infrastracture.yml \
  --stack-name code-infrastracture \
  --parameter-overrides file://${PARAMETER_DIR}/infrastracture.json \
  ${CHANGESET_OPTION} > /dev/null

aws cloudformation deploy \
  --template ${TEMPLATE_DIR}/server.yml \
  --stack-name code-server \
  --parameter-overrides file://${PARAMETER_DIR}/server.json \
  --capabilities CAPABILITY_IAM \
  ${CHANGESET_OPTION} > /dev/null

if [[ ${IS_DEPLOYMENT:-0} -eq 1 ]]; then
  EXPORTS_JSON="$(aws cloudformation list-exports)"
  TEMPLATE_ID="$(echo "$EXPORTS_JSON" | jq -r '.Exports[] | select(.Name == "code-server:TamplateId").Value')"
  LATEST_VERSION="$(echo "$EXPORTS_JSON" | jq -r '.Exports[] | select(.Name == "code-server:LatestTemplateVersion").Value')"
  aws ec2 modify-launch-template --launch-template-id "$TEMPLATE_ID" --default-version "$LATEST_VERSION" > /dev/null
fi

if [[ ${IS_DEPLOYMENT:-0} -eq 1 ]]; then
  echo "Success: Complete deploying stacks"
else
  echo "Success: Complete creating change-sets"
fi