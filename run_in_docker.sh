#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CMD=(bash -c "source ~/.bashrc; $*")

PROJECT_ROOT="$PWD"
DOCKER_HOME="$SCRIPT_DIR/docker-home"
SSH_PUBKEY=${SSH_PUBKEY:-"$HOME/.ssh/id_ed25519.pub"}

# `-t` requires a TTY on stdin/stdout; skip it when invoked from a
# non-interactive shell (CI, background tasks) so docker doesn't bail
# with "the input device is not a TTY". `-i` (stdin attached) is fine
# either way.
TTY_FLAG=
[ -t 0 ] && [ -t 1 ] && TTY_FLAG=-t

mkdir -p "$DOCKER_HOME" "$DOCKER_HOME"/.ssh && \
    cp "$SSH_PUBKEY" $DOCKER_HOME/.ssh/id_ed25519.pub

docker run -i $TTY_FLAG --rm \
    -v "$DOCKER_HOME":/home/node/:Z \
    -v "$PWD":/workspace:Z \
    ${SSH_AUTH_SOCK:+-v "$SSH_AUTH_SOCK":/ssh-agent -e SSH_AUTH_SOCK=/ssh-agent} \
    cww "${CMD[@]}"
