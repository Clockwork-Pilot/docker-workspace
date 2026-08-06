
``` sh
docker build -t cww .
export PATH="$PATH:~/git/clockwork-pilot/docker-workspace"

cd <project dir>
run_in_docker.sh "/create-venv.sh"
run_in_docker.sh "curl -fsSL https://claude.ai/install.sh | bash"
run_in_docker.sh "pip install -r /workspace/requirements.txt"
run_in_docker.sh "claude --dangerously-skip-permissions --plugin-dir /workspace"
run_in_docker.sh "bash -c 'echo 1'"
```

`run-docker.sh` assumes project dir in current folder and mounts the host repo at `/workspace` inside the container.

## Docker artifacts folder: docker-home/

The `docker-home/` directory is automatically created when running the Docker image via `run-docker.sh`. This folder contains persistent artifacts from the container.

Do not git commit it, this folder typically added to `.gitignore`

# Restrict Claude Code agent with clis-wrapper

Install and configure `clis-wrapper` to restrict access to dangerous commands like git operations:

## Install clis-wrapper with git deny rules

Prepare the git restrictions configuration and install clis-wrapper:


``` bash
# Create config for git restrictions
git_deny_config=$(cat <<'EOF'
{
  "namespaces": {
    "workspace": {
      "paths": ["/workspace"],
      "git": {
        "denied_subcommands": [
          "am", "apply", "archive", "bisect",
          "bundle", "checkout", "cherry-pick", "clean",
          "config", "describe", "fetch", "filter-branch", "filter-repo",
          "fsck", "gc", "grep", "init", "merge", "mv", "notes",
          "prune", "pull", "push", "rebase", "reflog", "remote", "repack",
          "replace", "reset", "restore", "revert", "rm", "shortlog",
          "stash", "switch", "symbolic-ref", "tag",
          "update-ref"
        ],
        "denied_patterns": ["--force(?:-with-lease)?", "-f\\b", "-C", "-C\\b", "--hard"]
      }
    }
  }
}
EOF
)

export PATH="$PATH:~/git/clockwork-pilot/docker-workspace"
# Install symlinks using proxy_wrapper.py CLI
run_in_docker.sh "
rm -rf ~/clis-wrapper
git clone https://github.com/Clockwork-Pilot/clis-wrapper.git ~/clis-wrapper
cat > ~/clis-wrapper-rules.json << EOF
"$git_deny_config"
EOF
cat ~/clis-wrapper-rules.json
python3 ~/clis-wrapper/proxy_wrapper.py --install --config ~/clis-wrapper-rules.json git gh chmod"

run_in_docker.sh "git reset THIS IS TEST WHICH SHOULD PROVE GIT IS RESTRICTED"
```

This creates symlinks in `~/.local/bin/` for each command that point to `proxy_wrapper.py`, and copies the rules config into the venv's etc directory.

Note: chmod is restricted in /workspace to avoid resetting read-only attributes where they are set

# Enable commits signing inside of docker
Optionally you want be able enable commits signing in docker container

``` bash
# Prepare script for docker
script=$(cat <<'EOF'
set -e

# Use forwarded SSH Key Inside of container
ssh-add -l
# test signature
echo "test" | ssh-keygen -Y sign     -f ~/.ssh/id_ed25519     -n file

# Set git repo settings
git config user.name  "$GIT_AUTHOR_NAME"
git config user.email "$GIT_AUTHOR_EMAIL"
git config --list

# Set global git settings
git config --global user.name  "$GIT_AUTHOR_NAME"
git config --global user.email "$GIT_AUTHOR_EMAIL"
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global gpg.format ssh
git config --global commit.gpgsign true
git config --global --list
EOF
)
```

``` bash
# Run script in docker
run_in_docker.sh "
export GIT_AUTHOR_NAME='Your Name'
export GIT_AUTHOR_EMAIL='your.email@example.com'
$script"
```
