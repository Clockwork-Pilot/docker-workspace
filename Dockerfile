FROM debian:bookworm

ARG TZ
ENV TZ="$TZ"

# Harness contract dependencies:
#   bash, git, gh — entrypoint
#   curl, wget, ca-certificates — fetching act, general scripting
#   sudo, gosu — entrypoint user drop
#   python3 + pip + venv — claude plugin venv
#   jq, less, procps, unzip — common scripting needs
#   openssh-client — ssh-add/ssh for forwarded SSH agent
RUN apt-get update && apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      curl \
      git \
      gh \
      gosu \
      jq \
      less \
      openssh-client \
      procps \
      python3 \
      python3-pip \
      python3-venv \
      sudo \
      unzip \
      wget \
      xz-utils \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Node.js v24 (official tarball; NodeSource/apt has no bookworm v24 line)
ARG NODE_VERSION=24.9.0
RUN set -eux; \
    case "$(dpkg --print-architecture)" in \
      amd64) NODE_ARCH=x64 ;; \
      arm64) NODE_ARCH=arm64 ;; \
      armhf) NODE_ARCH=armv7l ;; \
      *) echo "unsupported arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" -o /tmp/node.tar.xz; \
    tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 --no-same-owner \
        --exclude=CHANGELOG.md --exclude=LICENSE --exclude=README.md; \
    rm /tmp/node.tar.xz; \
    node --version; npm --version

ARG USERNAME=node
ARG HOME=/home/$USERNAME

# Hardcoded UID 1000 is a default identity; the entrypoint rebrands
# `node` to whatever HOST_UID/HOST_GID the caller passes, so published
# images work on any host without build-time UID plumbing.
RUN useradd -m -u 1000 $USERNAME \
    && mkdir -p $HOME/ \
    && chown -R $USERNAME:$USERNAME $HOME/ \
    && usermod -aG tty $USERNAME

COPY create-venv.sh /
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR /workspace
ENV WORKSPACE_ROOT=/workspace
ENV PATH="$HOME/.local/bin:$PATH"

USER root

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
