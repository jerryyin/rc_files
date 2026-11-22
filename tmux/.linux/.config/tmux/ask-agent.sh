#!/usr/bin/env bash
# Ask a throwaway question about text selected in a Claude Code or Codex pane.
#
#   ask-agent.sh open <agent-pane-id> [side|bottom]    selection on stdin
#
# Run by the tmux copy-mode bindings through copy-pipe. Finds the agent session
# behind the pane, then opens or reuses the answer pane, which runs the shared
# question loop in ask-agent-chat.sh.
set -u
umask 077
# The installed directory, where this Linux entry sits beside the shared files.
# Resolving the link would lead into the repository's platform subtree instead.
directory=$(cd "${BASH_SOURCE[0]%/*}" && pwd)

msg() { tmux display-message -d 4000 "ask-agent: $*"; }

# Print "<tool> <session-id> <cwd>" for the agent running under a pane.
find_session() {
  local root=$1 pid comm sid cwd
  # Descendants of the pane's shell, nearest first.
  local pids
  pids=$(ps -e -o pid=,ppid= | awk -v r="$root" '
    { kids[$2] = kids[$2] " " $1 }
    END { q[0] = r; n = 1; for (i = 0; i < n; i++) { print q[i]; m = split(kids[q[i]], k, " "); for (j = 1; j <= m; j++) q[n++] = k[j] } }')
  for pid in $pids; do
    comm=$(cat "/proc/$pid/comm" 2>/dev/null) || continue
    if [ "$comm" = claude ] && [ -f "$HOME/.claude/sessions/$pid.json" ]; then
      python3 -I -c 'import json,sys; d=json.load(open(sys.argv[1])); print("claude", d["sessionId"], d["cwd"])' \
        "$HOME/.claude/sessions/$pid.json"
      return
    fi
    if [ "$comm" = codex ]; then
      cwd=$(readlink "/proc/$pid/cwd") || continue
      sid=$(python3 -I "$directory/codex_session.py" "$pid" "$cwd") || return 1
      echo "codex $sid $cwd"
      return
    fi
  done
  return 1
}

cmd_open() {
  local agent=$1 layout=${2:-side} found tool sid cwd sel window
  if ! found=$(find_session "$(tmux display -p -t "$agent" '#{pane_pid}')"); then
    msg "no Claude Code or Codex session found in this pane"
    exit 0
  fi
  read -r tool sid cwd <<<"$found"
  window=$(tmux display -p -t "$agent" '#{window_id}') || return 1
  sel=$(mktemp "${TMPDIR:-/tmp}/ask-agent-XXXXXX") || exit 1
  cat >"$sel"
  if [ ! -s "$sel" ]; then
    rm -f -- "$sel"
    msg "nothing selected"
    exit 0
  fi
  local run
  run=$(printf '%q ' "$directory/ask-agent-chat.sh" "$agent" "$sel" "$tool" "$sid" "$cwd")
  python3 -I "$directory/ask_pane.py" "$agent" "$window" "$layout" "$run" || { rm -f -- "$sel"; return 1; }
}

case ${1:-} in
  open) shift; cmd_open "$@" ;;
  *) echo "usage: $0 open <pane-id> [side|bottom]" >&2; exit 2 ;;
esac
