
``` sh
export PATH="$PATH:~/git/clockwork-pilot/docker-workspace"
docker build -t cww .
cd <project dir>
run_in_docker.sh "/create-venv.sh"
run_in_docker.sh "curl -fsSL https://claude.ai/install.sh | bash"
run_in_docker.sh "pip install -r /workspace/requirements.txt"
run_in_docker.sh "claude --dangerously-skip-permissions --plugin-dir /workspace"
run_in_docker.sh "bash"
```

`run-docker.sh` assumes project dir in current folder and mounts the host repo at `/workspace` inside the container.

## Docker artifacts folder: docker-home/

The `docker-home/` directory is automatically created when running the Docker image via `run-docker.sh`. This folder contains persistent artifacts from the container.

Do not git commit it, this folder typically added to `.gitignore`.

# Optionally restricting claude code agent

You can use `git clone https://github.com/Clockwork-Pilot/clis-wrapper.git`
to restrict using chmod or any other tools inside of container.
