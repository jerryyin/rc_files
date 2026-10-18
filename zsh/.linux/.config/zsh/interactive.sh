if [ -t 1 ] && [ -z "${ZSH_VERSION:-}" ] && [ -z "${BASH_EXECUTION_STRING:-}" ] && command -v zsh >/dev/null 2>&1; then
    exec zsh -l
fi
