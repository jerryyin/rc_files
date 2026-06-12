#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error

# Check if `stow` is installed
if ! command -v stow >/dev/null 2>&1; then
    echo "Error: GNU Stow is not installed. Please install it and try again."
    exit 1
fi

# Clone rc_files if not already cloned
REPO_DIR="$HOME/rc_files"
if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning rc_files repository..."
    git clone https://github.com/jerryyin/rc_files.git "$REPO_DIR"
    git -C "$REPO_DIR" remote set-url origin git@github.com:jerryyin/rc_files.git
fi

BACKUP_DIR="${BACKUP_DIR:-$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)}"
REPO_REALPATH="$(realpath -m "$REPO_DIR")"

# Remove stale links from older package layouts, but only if they point into this repo.
echo "Cleaning up existing rc_files symlinks..."
while IFS= read -r -d '' link; do
    link_target="$(readlink "$link")"
    if [[ "$link_target" != /* ]]; then
        link_target="$(dirname "$link")/$link_target"
    fi
    link_target="$(realpath -m "$link_target")"

    if [[ "$link_target" = "$REPO_REALPATH" || "$link_target" = "$REPO_REALPATH"/* ]]; then
        echo "Removing stale symlink: $link -> $(readlink "$link")"
        rm "$link"
    fi
done < <(
    find "$HOME" -xdev -maxdepth "${STOW_CLEAN_MAX_DEPTH:-5}" \
        \( -path "$REPO_DIR" -o -path "$HOME/.cache" -o -path "$HOME/.local/share" -o -path "$HOME/.npm" -o -path "$HOME/.cargo" \) -prune \
        -o -type l -print0
)

# Back up real files that would block stow. Symlinks were handled above, and
# directories can be folded by stow.
echo "Backing up existing file conflicts..."
for package_dir in "$REPO_DIR"/*/; do
    package="$(basename "$package_dir")"

    while IFS= read -r -d '' tracked_path; do
        target="$HOME/${tracked_path#"$package"/}"
        if [ -e "$target" ] && [ ! -L "$target" ] && [ ! -d "$target" ]; then
            backup="$BACKUP_DIR/${target#"$HOME"/}"
            if [ -e "$backup" ] || [ -L "$backup" ]; then
                backup="$backup.$(date +%s)"
            fi

            echo "Backing up existing file: $target -> $backup"
            mkdir -p "$(dirname "$backup")"
            mv "$target" "$backup"
        fi
    done < <(git -C "$REPO_DIR" ls-files -z -- "$package")
done

# Use stow to manage dotfiles.
echo "Setting up dotfiles with stow..."
for package_dir in "$REPO_DIR"/*/; do
    package="$(basename "$package_dir")"
    stow -d "$REPO_DIR" "$package" -v -R -t "$HOME"
done

# Initialize vim-plug and install plugins
echo "Initializing vim-plug and installing Vim plugins..."
vim -E -s -u "$HOME/.vimrc" +PlugInstall +qall || true

# Install CoC extensions via npm (more reliable than vim's :CocInstall in non-interactive mode)
if command -v npm >/dev/null 2>&1; then
    echo "Installing CoC extensions..."
    COC_EXT_DIR="$HOME/.config/coc/extensions"
    mkdir -p "$COC_EXT_DIR"
    # Create package.json if it doesn't exist
    if [ ! -f "$COC_EXT_DIR/package.json" ]; then
        echo '{"dependencies":{}}' > "$COC_EXT_DIR/package.json"
    fi
    # Some environments (corporate proxies, WSL) present a TLS chain npm cannot
    # verify, causing UNABLE_TO_GET_ISSUER_CERT_LOCALLY. Prefer a configured CA
    # bundle; otherwise fall back to disabling strict-ssl for this install.
    NPM_TLS_FLAGS=()
    if [ -n "${NODE_EXTRA_CA_CERTS:-}" ] && [ -f "${NODE_EXTRA_CA_CERTS}" ]; then
        NPM_TLS_FLAGS+=(--cafile "${NODE_EXTRA_CA_CERTS}")
    else
        NPM_TLS_FLAGS+=(--strict-ssl=false)
    fi
    cd "$COC_EXT_DIR" && npm install --no-save "${NPM_TLS_FLAGS[@]}" coc-json coc-tsserver coc-pyright coc-snippets || true
else
    echo "Note: npm not found. Install CoC extensions manually in vim with :CocInstall coc-json coc-tsserver coc-pyright coc-snippets"
fi

# Install tmux plugin manager
TMUX_PLUGIN_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TMUX_PLUGIN_DIR" ]; then
    echo "Installing tmux plugin manager..."
    git clone https://github.com/tmux-plugins/tpm "$TMUX_PLUGIN_DIR"
fi

# Install tmux plugins
# Start a detached tmux session to source tmux.conf and initialize TPM, then install plugins
if [ -d "$TMUX_PLUGIN_DIR" ] && [ -f "$HOME/.tmux.conf" ]; then
    echo "Installing tmux plugins..."
    tmux new-session -d -s _tpm_install "sleep 2" 2>/dev/null && sleep 0.5
    "$TMUX_PLUGIN_DIR/bin/install_plugins" || true
    tmux kill-session -t _tpm_install 2>/dev/null || true
fi

# Make Zsh the default shell and configure Zsh
echo "Setting Zsh as the default shell and configuring Zsh..."
if command -v zsh >/dev/null 2>&1; then
    ZSH_PATH="$(command -v zsh)"
    CURRENT_USER="${USER:-$(whoami)}"
    CURRENT_SHELL="$(getent passwd "$CURRENT_USER" 2>/dev/null | cut -d: -f7)"

    if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
        echo "Zsh is already the default shell; skipping chsh."
    # Changing your OWN login shell does not require sudo; chsh prompts for your
    # password when a terminal is available. Try non-interactively first (-n),
    # then fall back to an interactive chsh, then to clear manual instructions.
    elif sudo -n chsh -s "$ZSH_PATH" "$CURRENT_USER" 2>/dev/null; then
        echo "Default shell changed to zsh (passwordless sudo)."
    elif [ -t 0 ] && chsh -s "$ZSH_PATH"; then
        echo "Default shell changed to zsh."
    else
        echo "WARNING: Could not change default shell automatically (no terminal/password available)."
        echo "         Run this manually later:  chsh -s \"$ZSH_PATH\""
    fi
    
    # Process .zshrc to remove 'wait' from zinit ice for initial plugin install
    TEMP_ZSHRC="/tmp/zshrc_processed"
    sed "/zinit ice/s/wait'[^']*'//g" "$HOME/.zshrc" > "$TEMP_ZSHRC"
    zsh -c "source $TEMP_ZSHRC; exit" || true
else
    echo "Error: Zsh is not installed. Please install it and re-run this script."
    exit 1
fi

echo "Setup completed successfully!"
