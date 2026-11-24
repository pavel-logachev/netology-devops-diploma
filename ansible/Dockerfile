FROM python:3.13-alpine

RUN apk add --no-cache openssh-client \
    && pip install --no-cache-dir ansible-core==2.21.2

# Каталог проекта монтируется из Windows с правами 777, поэтому настройки
# передаются переменными окружения, а не через ansible.cfg.
ENV ANSIBLE_PIPELINING=True \
    ANSIBLE_FORKS=10 \
    ANSIBLE_HOST_KEY_CHECKING=False \
    ANSIBLE_SSH_ARGS="-o ControlMaster=auto -o ControlPersist=60s -o ServerAliveInterval=15 -o ServerAliveCountMax=4" \
    ANSIBLE_TIMEOUT=60 \
    ANSIBLE_STDOUT_CALLBACK=default \
    ANSIBLE_CALLBACK_RESULT_FORMAT=yaml

# Ключ монтируется только для чтения; ssh требует права 600.
ENTRYPOINT ["/bin/sh", "-c", "mkdir -p /root/.ssh && cp /secrets/id_ed25519 /root/.ssh/id_ed25519 && chmod 600 /root/.ssh/id_ed25519 && exec ansible-playbook \"$@\"", "--"]
