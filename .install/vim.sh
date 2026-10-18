#!/bin/bash
set -eu

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
    . "$HOME/.config/node/ca-cert.sh"
    NPM_TLS_FLAGS=()
    if [ -n "${NODE_EXTRA_CA_CERTS:-}" ] && [ -f "${NODE_EXTRA_CA_CERTS}" ]; then
        NPM_TLS_FLAGS+=(--cafile "${NODE_EXTRA_CA_CERTS}")
    fi
    EXTENSIONS="$(python3 -c 'import json,sys; print("\n".join(json.load(open(sys.argv[1]))))' "$HOME/.vim/coc-extensions.json")"
    mapfile -t COC_EXTENSIONS <<< "$EXTENSIONS"
    ( cd "$COC_EXT_DIR" && npm install --no-save "${NPM_TLS_FLAGS[@]}" "${COC_EXTENSIONS[@]}" ) \
        || echo "WARNING: CoC extension installation failed; continuing setup." >&2
else
    echo "Note: npm not found. CoC will use the shared choices in ~/.vim/coc-extensions.json when Node is available."
fi
