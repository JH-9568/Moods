#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${1:-.env}"
IOS_ENV_FILE="ios/Flutter/Env.xcconfig"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Env file '${ENV_FILE}' not found. Create it from .env.example first." >&2
  exit 1
fi

read_env() {
  local key="$1"
  local value
  value="$(grep -E "^${key}=" "${ENV_FILE}" | tail -n 1 | cut -d '=' -f 2-)"
  echo "${value}"
}

maps_ios="$(read_env MAPS_API_KEY_IOS)"
if [[ -z "${maps_ios}" ]]; then
  maps_ios="$(read_env MAPS_API_KEY)"
fi
kakao_key="$(read_env KAKAO_NATIVE_APP_KEY)"

cat > "${IOS_ENV_FILE}" <<EOF
// Generated from ${ENV_FILE}. Do not commit this file.
MAPS_API_KEY_IOS = ${maps_ios}
KAKAO_NATIVE_APP_KEY = ${kakao_key}
KAKAO_URL_SCHEME = kakao${kakao_key}
EOF

echo "Wrote ${IOS_ENV_FILE}"
