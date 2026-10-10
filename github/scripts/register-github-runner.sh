#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_REPOSITORY_URL:?Set GITHUB_REPOSITORY_URL before running this script}"
: "${GITHUB_RUNNER_TOKEN:?Set GITHUB_RUNNER_TOKEN before running this script}"

RUNNER_NAME="${RUNNER_NAME:-aws-runner}"
RUNNER_LABELS="${RUNNER_LABELS:-aws}"
RUNNER_DIR="${RUNNER_DIR:-/opt/actions-runner}"

echo "Registering GitHub Actions runner..."
cd "$RUNNER_DIR"

sudo -u github-runner ./config.sh \
  --url "$GITHUB_REPOSITORY_URL" \
  --token "$GITHUB_RUNNER_TOKEN" \
  --name "$RUNNER_NAME" \
  --labels "$RUNNER_LABELS" \
  --unattended \
  --replace

echo "Installing runner service..."
sudo ./svc.sh install github-runner
sudo ./svc.sh start

echo "GitHub Actions runner registered successfully."
