#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=2050 # This isn't a constant string, it's a TeamCity variable substitution
if [[ "%TEST_PATTERN%" == "" || "%TEST_PATTERN%" == "TestAcc" ]]; then
  echo "Invalid test filter pattern: \"%TEST_PATTERN%\""
  exit 1
fi

echo "Filtering acceptance tests: %TEST_PATTERN%"

TEST_LIST=$(go test ./... -list="%TEST_PATTERN%" 2>/dev/null)

read -r -a split <<<"${TEST_LIST}"
TEST_COUNT=${#split[@]}

if [[ "${TEST_COUNT}" == 0 ]]; then
	echo "Zero tests"
	exit 0
elif [[ "${TEST_COUNT}" == 1 ]]; then
	echo "Running 1 test:"
else
	echo "Running ${TEST_COUNT} tests:"
fi
echo "${TEST_LIST}"
echo

conf=$(pwd)/aws.conf

function cleanup {
  rm "${conf}"
}
trap cleanup EXIT

touch "${conf}"
chmod 600 "${conf}"
cat << EOF > "${conf}"
[profile sweeper]
role_arn = %ACCTEST_ROLE_ARN%
source_profile = source

[profile source]
aws_access_key_id     = %env.AWS_ACCESS_KEY_ID%
aws_secret_access_key = %env.AWS_SECRET_ACCESS_KEY%
EOF

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY

AWS_CONFIG_FILE="${conf}" AWS_PROFILE=sweeper TF_ACC=1 go test ./... -run="%TEST_PATTERN%" -v -count=1 -parallel "%ACCTEST_PARALLELISM%" -timeout=0
