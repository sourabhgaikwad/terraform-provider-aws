#!/usr/bin/env bash

set -euo pipefail

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

# All of internal except for internal/service. This list should be generated.
AWS_CONFIG_FILE="${conf}" AWS_PROFILE=sweeper TF_ACC=1 go test \
    ./internal/acctest/... \
    ./internal/conns/... \
    ./internal/create/... \
    ./internal/experimental/... \
    ./internal/flex/... \
    ./internal/generate/... \
    ./internal/provider/... \
    ./internal/tags/... \
    ./internal/tfresource/... \
    ./internal/vault/... \
    ./internal/verify/... \
    -json -v -count=1 -parallel "%ACCTEST_PARALLELISM%" -timeout=0 -run=TestAcc
