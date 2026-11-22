#!/usr/bin/env bash
# Run the shared ask-agent question loop in a psmux pane under Git for Windows bash.
#
#   ask-agent-run.sh <ask-agent-chat.sh> <pane-number> <passage-file> -- <resolver> [args...]
#
# The pane id arrives without its % and is restored here. The loop calls tmux to
# return focus to the source pane, so tmux is defined as psmux, with MSYS path
# conversion off so pane ids and options pass through unchanged.
export PATH="/usr/bin:$PATH"
tmux() { MSYS2_ARG_CONV_EXCL='*' psmux.exe "$@"; }
chat=$1 pane=$2
shift 2
source "$chat" "%$pane" "$@"
