#!/usr/bin/env bash
# Запуск Ansible в контейнере (на Windows нет нативного Ansible).
# Пример: scripts/ansible.sh            – весь site.yml
#         scripts/ansible.sh --tags x   – дополнительные аргументы ansible-playbook
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$(pwd -W 2>/dev/null || pwd)
docker build -q -t diploma-ansible:2.21.2 -f ansible/Dockerfile ansible >/dev/null
exec docker run --rm \
  -v "$ROOT:/work" -v "$ROOT/.secrets:/secrets:ro" -w /work/ansible \
  diploma-ansible:2.21.2 -i "${INVENTORY:-inventory.yml}" site.yml -e @/secrets/passwords.yml "$@"
