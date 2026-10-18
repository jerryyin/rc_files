#!/bin/bash
set -eu

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
