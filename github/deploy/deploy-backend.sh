#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ne 2 ]]; then
  echo "Usage: $0 <dockerhub-user> <image-tag>" >&2
  exit 2
fi

registry="$1"
image_tag="$2"
parameter_prefix="${DB_PARAMETER_PREFIX:-/saludos/prod/db}"
env_file="/opt/saludos/backend.env"

get_parameter() {
  aws ssm get-parameter +    --name "${parameter_prefix}/$1" +    --with-decryption +    --query 'Parameter.Value' +    --output text
}

db_host="$(get_parameter host)"
db_port="$(get_parameter port)"
db_name="$(get_parameter name)"
db_user="$(get_parameter user)"
db_password="$(get_parameter password)"

install -d -m 700 /opt/saludos
install -m 600 /dev/null "$env_file"
printf '%s\n' +  "DB_HOST=${db_host}" +  "DB_PORT=${db_port}" +  "DB_NAME=${db_name}" +  "DB_USER=${db_user}" +  "DB_PASSWORD=${db_password}" +  "DB_SSLMODE=require" >"$env_file"

image="${registry}/backend:${image_tag}"
docker pull "$image"
docker rm -f backend >/dev/null 2>&1 || true
docker run -d +  --name backend +  --restart unless-stopped +  --env-file "$env_file" +  -p 5000:5000 +  "$image"

for attempt in $(seq 1 30); do
  if curl --fail --silent http://localhost:5000/health >/dev/null; then
    echo "Backend release ${image_tag} is healthy."
    exit 0
  fi
  echo "Waiting for backend: attempt ${attempt}/30"
  sleep 2
done

docker logs backend
exit 1
