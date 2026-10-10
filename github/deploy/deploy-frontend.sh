#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ne 3 ]]; then
  echo "Usage: $0 <dockerhub-user> <image-tag> <backend-private-dns>" >&2
  exit 2
fi

registry="$1"
image_tag="$2"
backend_host="$3"
image="${registry}/frontend:${image_tag}"

docker pull "$image"
docker rm -f frontend >/dev/null 2>&1 || true
docker run -d +  --name frontend +  --restart unless-stopped +  -e "BACKEND_HOST=${backend_host}" +  -e BACKEND_PORT=5000 +  -p 8080:80 +  "$image"

for attempt in $(seq 1 30); do
  if curl --fail --silent http://localhost:8080/health >/dev/null; then
    echo "Frontend release ${image_tag} is healthy."
    exit 0
  fi
  echo "Waiting for frontend: attempt ${attempt}/30"
  sleep 2
done

docker logs frontend
exit 1
