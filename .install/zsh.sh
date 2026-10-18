#!/bin/bash
set -eu

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
    GIT_CONFIG_GLOBAL=/dev/null GIT_TERMINAL_PROMPT=0 zsh -c "source $TEMP_ZSHRC; exit" || true
else
    echo "Error: Zsh is not installed. Please install it and re-run this script."
    exit 1
fi
