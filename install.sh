#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error

# The repository and Python are sufficient for configuration deployment.
for dep in python3 git curl; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        echo "Error: '$dep' is not installed. Please install it and try again."
        exit 1
    fi
done
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${BACKUP_DIR:-$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)}"
python3 "$REPO_DIR/.deploy/deploy.py" migrate --home "$HOME" --backup "$BACKUP_DIR"
[ ! -d "$HOME/.ssh" ] || chmod 700 "$HOME/.ssh"

for setup in "$REPO_DIR"/.install/*.sh; do
    bash "$setup"
done

echo "Setup completed successfully!"
