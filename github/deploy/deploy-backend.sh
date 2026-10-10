#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -lt 2 || "$#" -gt 3 ]]; then
  echo "Usage: $0 <dockerhub-user> <image-tag> [aws-region]" >&2
  exit 2
fi

registry="$1"
image_tag="$2"
aws_region="${3:-${AWS_REGION:-us-east-1}}"
parameter_prefix="${DB_PARAMETER_PREFIX:-/saludos/prod/db}"
env_file="/opt/saludos/backend.env"

get_parameter() {
  aws ssm get-parameter \
    --region "$aws_region" \
    --name "${parameter_prefix}/$1" \
    --query 'Parameter.Value' \
    --output text
}

db_host="$(get_parameter host)"
db_port="$(get_parameter port)"
db_name="$(get_parameter name)"
secret_arn="$(get_parameter secret-arn)"
secret_json="$(aws secretsmanager get-secret-value \
  --region "$aws_region" \
  --secret-id "$secret_arn" \
  --query SecretString \
  --output text)"
db_user="$(jq -er '.username' <<<"$secret_json")"
db_password="$(jq -er '.password' <<<"$secret_json")"

install -d -m 700 /opt/saludos
install -m 600 /dev/null "$env_file"
printf '%s\n' \
  "DB_HOST=${db_host}" \
  "DB_PORT=${db_port}" \
  "DB_NAME=${db_name}" \
  "DB_USER=${db_user}" \
  "DB_PASSWORD=${db_password}" \
  "DB_SSLMODE=require" >"$env_file"

# RDS does not execute github/db/init.sql automatically. Initialize the
# application schema idempotently from the private backend instance.
docker run --rm -i \
  -e "PGPASSWORD=${db_password}" \
  -e PGSSLMODE=require \
  postgres:16-alpine \
  psql \
    --host "$db_host" \
    --port "$db_port" \
    --username "$db_user" \
    --dbname "$db_name" \
    --set ON_ERROR_STOP=1 <<'SQL'
CREATE TABLE IF NOT EXISTS saludos (
    id SERIAL PRIMARY KEY,
    mensaje VARCHAR(255) NOT NULL UNIQUE
);

INSERT INTO saludos (mensaje) VALUES
('¡Hola! Espero que tengas un excelente día.'),
('¡Hola desde la arquitectura de tres capas!'),
('¡Saludos desde PostgreSQL!'),
('¡Bienvenido al entregable DevOps en AWS!'),
('¡Tu solicitud pasó por el balanceador, frontend, backend y RDS!'),
('¡Todo funciona correctamente!'),
('¡Saludos desde el backend!'),
('¡La base de datos respondió correctamente!')
ON CONFLICT (mensaje) DO NOTHING;
SQL

image="${registry}/backend:${image_tag}"
docker pull "$image"
docker rm -f backend >/dev/null 2>&1 || true
docker run -d \
  --name backend \
  --restart unless-stopped \
  --env-file "$env_file" \
  -p 5000:5000 \
  "$image"

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
