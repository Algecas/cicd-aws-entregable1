#!/usr/bin/env bash
set -e

# ============================================
# DATOS A COMPLETAR:
# ============================================

GITHUB_REPOSITORY_URL="https://github.com/Algecas/cicd"
GITHUB_RUNNER_TOKEN="AP6DRGCK5NVGSDIVVOYBANTKVMROA"

RUNNER_NAME="vagrant-runner"
RUNNER_LABELS="self-hosted,linux,x64,vagrant"
RUNNER_DIR="/opt/actions-runner"

# ============================================
# REGISTRO DEL RUNNER
# ============================================

echo "Registrando runner en GitHub..."

cd "$RUNNER_DIR"

sudo -u github-runner ./config.sh \
  --url "$GITHUB_REPOSITORY_URL" \
  --token "$GITHUB_RUNNER_TOKEN" \
  --name "$RUNNER_NAME" \
  --labels "$RUNNER_LABELS" \
  --unattended

echo "Instalando runner como servicio..."

sudo ./svc.sh install github-runner
sudo ./svc.sh start

echo "GitHub Actions Runner registrado correctamente."
