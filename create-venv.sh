set -e

# called from user-entrypoint.sh script (from inside of docker)
python3 -m venv ~/venv
source ~/venv/bin/activate

cat > ~/.bashrc << 'EOF'
source ~/venv/bin/activate
EOF
