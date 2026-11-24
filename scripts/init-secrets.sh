#!/usr/bin/env bash
# Создает временный SSH-ключ и пароли сервисов в .secrets/ (каталог в .gitignore).
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .secrets
[ -f .secrets/id_ed25519 ] || ssh-keygen -q -t ed25519 -N '' -C netology-diploma -f .secrets/id_ed25519
if [ ! -f .secrets/passwords.yml ]; then
  for k in elastic_password kibana_system_password filebeat_password kibana_viewer_password grafana_admin_password; do
    echo "$k: \"$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 20)\""
  done > .secrets/passwords.yml
fi
echo "OK: .secrets/id_ed25519, .secrets/passwords.yml"
