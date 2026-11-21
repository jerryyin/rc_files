#!/usr/bin/env bash
# Ask a throwaway question about text selected in a Claude Code or Codex pane.
#
#   ask-agent.sh open <agent-pane-id>     selection on stdin (tmux copy-pipe)
#   ask-agent.sh run <agent-pane-id> <tool> <session-id> <cwd> <selection-file>
#
# `open` finds the agent session behind the pane and opens the answer pane by
# splitting another pane of the window, so the agent pane keeps its size. The
# answer pane is reused for later questions. `run` asks the question in a
# temporary fork of the session; the original conversation is not changed.
set -u
umask 077
export PATH="$HOME/.local/bin:$PATH"
self=${BASH_SOURCE[0]//\\//}
directory=${self%/*}
if [[ $OSTYPE == cygwin* || $OSTYPE == msys* ]]; then
  export PATH="/usr/bin:$PATH"
  tmux() { MSYS2_ARG_CONV_EXCL='*' psmux.exe "$@"; }
fi

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
  local agent=$1 found tool sid cwd sel window
  self=$(readlink -f "$self") || return 1
  directory=${self%/*}
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
  run=$(printf '%q ' "$self" run "$agent" "$tool" "$sid" "$cwd" "$sel")
  python3 -I "$directory/ask_pane.py" "$agent" "$window" "${2:-side}" "$run" || { rm -f -- "$sel"; return 1; }
}

# Ask one question in a fresh throwaway fork; the answer lands in $out.
ask() {
  local tool=$1 sid=$2 cwd=$3 prompt=$4 out=$5 err=$6
  local dim=$'\e[2m' off=$'\e[0m'
  : >"$out"
  (
    # The session's directory may have been deleted since it started. Resuming
    # by id works from any directory, so fall back to the nearest that exists.
    while [ ! -d "$cwd" ]; do cwd=$(dirname "$cwd"); done
    cd "$cwd" || exit 1
    case $tool in
      # On stdin: --tools takes a list and would swallow a prompt argument.
      claude) claude -p --resume "$sid" --fork-session --no-session-persistence \
                --tools Read,Grep,Glob <<<"$prompt" >"$out" ;;
      codex) codex exec fork "$sid" --ephemeral -c 'sandbox_mode="read-only"' \
               --skip-git-repo-check -o "$out" - <<<"$prompt" >/dev/null ;;
    esac
  ) 2>"$err" &
  local job=$! t=0
  while kill -0 "$job" 2>/dev/null; do
    printf '\r%sthinking… %ds%s' "$dim" "$t" "$off"
    sleep 1
    t=$((t + 1))
  done
  wait "$job"
  local status=$?
  printf '\r\e[K'
  [ "$status" -eq 0 ] && [ -s "$out" ]
}

cmd_run() {
  local agent=$1 tool=$2 sid=$3 cwd=$4 sel=$5
  local dim=$'\e[2m' bold=$'\e[1m' off=$'\e[0m'
  local out="$sel.answer" err="$sel.error"
  trap 'rm -f -- "$sel" "$out" "$err"; tmux select-pane -t "$agent" 2>/dev/null' EXIT
  local context passage line lines=0
  if [ "$tool" = auto ]; then
    { IFS= read -r context; IFS= read -r -d '' passage || :; } <"$sel"
  else
    passage=$(<"$sel")
  fi
  rm -f -- "$sel"
  set -o history  # Up recalls earlier questions in this pane.
  local heading="$tool session ${sid:0:8}"
  [ "$tool" = auto ] && heading='Ask about this selection'
  printf '%s%s · empty line closes%s\n\n' "$dim" "$heading" "$off"
  while IFS= read -r line; do
    (( ++lines ))
    (( lines <= 12 )) && printf '%s│ %s%s\n' "$dim" "$line" "$off"
  done <<<"${passage%$'\n'}"
  (( lines > 12 )) && printf '%s│ … (%d more lines)%s\n' "$dim" "$((lines - 12))" "$off"

  # Every question is a new fork of the unchanged main session, so a follow-up
  # sees the earlier side questions only through this transcript.
  local label=Question question prompt thread=''
  while :; do
    echo
    # \001 and \002 tell readline the colour codes take no width; without them
    # it misplaces the cursor once the question wraps and the text seems to vanish.
    read -r -e -p $'\001'"$bold"$'\002'"$label>"$'\001'"$off"$'\002 ' question || exit 0
    [ -n "$question" ] || exit 0
    if [ "$tool" = auto ]; then
      local session
      session=$(printf '%s\n%s' "$context" "$passage" | py -3 "$HOME/.tmux/ask-agent.py" resolve) || continue
      [ -n "$session" ] || exit 0
      IFS=$'\t' read -r tool sid cwd <<<"$session"
      if [ "$sid" = choose ]; then
        session=$(py -3 "$directory/codex_session.py" choose "$cwd") || { tool=auto; continue; }
        [ -n "$session" ] || exit 0
        IFS=$'\t' read -r sid cwd <<<"$session"
      fi
      printf '%s%s session %s%s\n' "$dim" "$tool" "${sid:0:8}" "$off"
    fi
    history -s -- "$question"
    prompt=$(printf '%s\n\n<passage>\n%s\n</passage>\n' \
      "This is a side question about a passage from the conversation above, which the user selected in the terminal. Answer only the question, concisely and in plain words. Do not continue the main task and do not change any files." \
      "${passage%$'\n'}")
    [ -n "$thread" ] && prompt+=$'\n'"Earlier side questions about this passage, with your answers:"$'\n'"$thread"
    prompt+=$'\n'"Question: $question"
    echo
    if ask "$tool" "$sid" "$cwd" "$prompt" "$out" "$err"; then
      cat "$out"
      thread+=$'\n'"<question>$question</question>"$'\n'"<answer>$(cat "$out")</answer>"$'\n'
      label=Follow-up
    else
      printf '%s%s failed:%s\n' "$bold" "$tool" "$off"
      tail -n 20 "$err"
    fi
    rm -f -- "$out" "$err"
  done
}

case ${1:-} in
  open) shift; cmd_open "$@" ;;
  run-windows) cmd_run "%$2" auto auto . "$3" ;;
  run) shift; cmd_run "$@" ;;
  *) echo "usage: $0 open <pane-id> | run ..." >&2; exit 2 ;;
esac
