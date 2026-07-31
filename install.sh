#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error

# Check required dependencies up front.
for dep in stow git curl; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        echo "Error: '$dep' is not installed. Please install it and try again."
        exit 1
    fi
done

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

# Create every directory the packages install into, before stowing them.
#
# Left to itself, stow "folds": when a directory in $HOME doesn't exist yet
# and only one package supplies it, stow points a single symlink at the
# package -- ~/.config becomes a link to rc_files/nvim/.config -- instead of
# linking the files inside it. Everything any program then writes anywhere
# under ~/.config lands in this repo. That is how 66MB of coc extensions and
# tmux plugins, and a ~/.docker/config.json holding registry credentials,
# came to live in the working tree, invisible only because the global
# gitignore hides dot-prefixed paths. A directory that already exists is
# nothing to fold, so stow links file by file and runtime writes stay in
# $HOME where they belong.
echo "Pre-creating target directories so stow can't fold them..."
for package_dir in "$REPO_DIR"/*/; do
    while IFS= read -r -d '' dir; do
        mkdir -p "$HOME/${dir#"$package_dir"}"
    done < <(find "$package_dir" -mindepth 1 -type d -print0)
done
# mkdir honours the umask, which would leave a freshly created ~/.ssh at 755.
[ -d "$HOME/.ssh" ] && chmod 700 "$HOME/.ssh"

# Use stow to manage dotfiles.
echo "Setting up dotfiles with stow..."
for package_dir in "$REPO_DIR"/*/; do
    package="$(basename "$package_dir")"
    stow -d "$REPO_DIR" "$package" -v -R -t "$HOME"
done

# Initialize vim-plug and install plugins
if command -v vim >/dev/null 2>&1; then
    echo "Initializing vim-plug and installing Vim plugins..."
    if ! GIT_CONFIG_GLOBAL=/dev/null vim -n -E -s -u "$HOME/.vimrc" \
        "+PlugInstall --sync" \
        "+if !empty(filter(values(g:plugs), '!isdirectory(v:val.dir)')) | cquit 1 | endif" \
        "+qall!"; then
        echo "WARNING: Vim plugin installation failed; continuing setup." >&2
    fi
else
    echo "Note: vim not found. Skipping vim-plug plugin installation."
fi

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
    # verify, causing UNABLE_TO_GET_ISSUER_CERT_LOCALLY. Point npm at the OS's
    # CA bundle rather than disabling verification; self-sufficient here
    # (doesn't assume .zshrc/min.sh already set this) since install.sh can run
    # standalone.
    . "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/node-ca-cert.sh"
    NPM_TLS_FLAGS=()
    if [ -n "${NODE_EXTRA_CA_CERTS:-}" ] && [ -f "${NODE_EXTRA_CA_CERTS}" ]; then
        NPM_TLS_FLAGS+=(--cafile "${NODE_EXTRA_CA_CERTS}")
    fi
    ( cd "$COC_EXT_DIR" && npm install --no-save "${NPM_TLS_FLAGS[@]}" coc-json coc-tsserver coc-pyright coc-snippets ) \
        || echo "WARNING: CoC extension installation failed; continuing setup." >&2
else
    echo "Note: npm not found. Install CoC extensions manually in vim with :CocInstall coc-json coc-tsserver coc-pyright coc-snippets"
fi

# Install tmux plugin manager
TMUX_PLUGIN_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TMUX_PLUGIN_DIR" ]; then
    echo "Installing tmux plugin manager..."
    GIT_CONFIG_GLOBAL=/dev/null GIT_TERMINAL_PROMPT=0 \
        git clone https://github.com/tmux-plugins/tpm "$TMUX_PLUGIN_DIR" \
        || echo "WARNING: Failed to clone tmux plugin manager; continuing setup." >&2
fi

# tmux only reads ~/.tmux.conf when its *server* starts, not on later
# `new-session` calls to an already-running one.
reload_tmux_conf_if_server_running() {
    if tmux has-session 2>/dev/null; then
        tmux source-file "$HOME/.tmux.conf" \
            || echo "WARNING: Failed to reload ~/.tmux.conf; continuing setup." >&2
    fi
}

# Install tmux plugins
# Start a detached tmux session to source tmux.conf and initialize TPM, then install plugins
if command -v tmux >/dev/null 2>&1 && [ -d "$TMUX_PLUGIN_DIR" ] && [ -f "$HOME/.tmux.conf" ]; then
    echo "Installing tmux plugins..."

    reload_tmux_conf_if_server_running
    tmux new-session -d -s _tpm_install "sleep 2" 2>/dev/null && sleep 0.5
    GIT_CONFIG_GLOBAL=/dev/null GIT_TERMINAL_PROMPT=0 \
        "$TMUX_PLUGIN_DIR/bin/install_plugins" \
        || echo "WARNING: tmux plugin installation failed; continuing setup." >&2
    tmux kill-session -t _tpm_install 2>/dev/null || true
    reload_tmux_conf_if_server_running
fi

# Make Zsh the default shell and configure Zsh
echo "Setting Zsh as the default shell and configuring Zsh..."
if command -v zsh >/dev/null 2>&1; then
    ZSH_PATH="$(command -v zsh)"
    CURRENT_USER="${USER:-$(whoami)}"
    CURRENT_SHELL="$(getent passwd "$CURRENT_USER" 2>/dev/null | cut -d: -f7)"

    if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
        echo "Zsh is already the default shell; skipping chsh."
    # Exactly one chsh attempt, and it never prompts. In a container this is
    # the path that runs: root with passwordless sudo and a real local
    # /etc/passwd entry, so the login shell genuinely changes.
    #
    # There is deliberately NO interactive `chsh` fallback. It used to be
    # guarded by `[ -t 0 ]`, on the theory that a terminal implies someone
    # is there to type a password -- but a terminal only means a tty is
    # attached, not that a human is watching it. Any automated run over
    # `ssh -tt` satisfies that test and then blocks forever on chsh's
    # password prompt. Worse, on the hosts where that branch was actually
    # reached it could never have succeeded anyway: they authenticate
    # against an external directory, so `getent passwd` resolves the user
    # while /etc/passwd has no entry at all for chsh to rewrite. It was a
    # prompt that could only ever hang, never succeed.
    elif sudo -n chsh -s "$ZSH_PATH" "$CURRENT_USER" 2>/dev/null; then
        echo "Default shell changed to zsh (passwordless sudo)."
    else
        # No local /etc/passwd entry to rewrite (externally-managed account),
        # or no passwordless sudo. Either way the login shell can't be changed
        # without prompting, so auto-exec zsh from .bashrc instead: interactive
        # bash logins still land in zsh, and no account metadata owned by that
        # external system gets touched.
        SHIM_MARKER="# >>> rc_files: auto-exec zsh (chsh unavailable) >>>"
        if ! grep -qF "$SHIM_MARKER" "$HOME/.bashrc" 2>/dev/null; then
            {
                echo ""
                echo "$SHIM_MARKER"
                echo "if [ -t 1 ] && [ -z \"\${ZSH_VERSION:-}\" ] && [ -z \"\${BASH_EXECUTION_STRING:-}\" ] && [ -x \"$ZSH_PATH\" ]; then"
                echo "    exec \"$ZSH_PATH\" -l"
                echo "fi"
                echo "# <<< rc_files: auto-exec zsh (chsh unavailable) <<<"
            } >> "$HOME/.bashrc"
            echo "chsh unavailable (no local /etc/passwd entry for $CURRENT_USER); added an auto-exec-zsh shim to ~/.bashrc instead."
            echo "  (if this account does have a local passwd entry, 'chsh -s $ZSH_PATH' by hand sets the login shell properly)"
        else
            echo "chsh unavailable; auto-exec-zsh shim already present in ~/.bashrc."
        fi
    fi
    
    # Process .zshrc to remove 'wait' from zinit ice for initial plugin install.
    # Use a private temp file (not a predictable /tmp path) and clean it up.
    TEMP_ZSHRC="$(mktemp "${TMPDIR:-/tmp}/zshrc_processed.XXXXXX")"
    trap 'rm -f "$TEMP_ZSHRC"' EXIT
    sed "/zinit ice/s/wait'[^']*'//g" "$HOME/.zshrc" > "$TEMP_ZSHRC"
    zsh -c "source $TEMP_ZSHRC; exit" || true
else
    echo "Error: Zsh is not installed. Please install it and re-run this script."
    exit 1
fi

echo "Setup completed successfully!"
