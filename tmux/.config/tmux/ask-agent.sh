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
export PATH="$HOME/.local/bin:$PATH"
state="${TMPDIR:-/tmp}/ask-agent-$(id -u)"
mkdir -p "$state"
self=$(readlink -f "$0")

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
      sid=$(codex_thread "$pid" "$cwd") || return 1
      echo "codex $sid $cwd"
      return
    fi
  done
  return 1
}

# The Codex thread a process is writing: the rollout file it holds open, else
# the most recently active thread started in its directory.
codex_thread() {
  python3 -I - "$1" "$2" "${CODEX_HOME:-$HOME/.codex}" <<'EOF'
import glob, os, sqlite3, sys
pid, cwd, home = sys.argv[1:]
open_files = set()
for fd in glob.glob(f"/proc/{pid}/fd/*"):
    try:
        open_files.add(os.readlink(fd))
    except OSError:
        pass
dbs = sorted(glob.glob(os.path.join(home, "state_*.sqlite")))
if not dbs:
    sys.exit(1)
db = sqlite3.connect(f"file:{dbs[-1]}?mode=ro", uri=True)
rows = db.execute("select id, rollout_path, cwd from threads where archived = 0 "
                  "order by recency_at_ms desc, updated_at desc").fetchall()
for tid, path, _ in rows:
    if path in open_files:
        print(tid); sys.exit(0)
for tid, _, tcwd in rows:
    if tcwd == cwd:
        print(tid); sys.exit(0)
sys.exit(1)
EOF
}

# The pane to split for the answer: another pane of the window, preferring one
# beside the agent pane (no shared columns), then the largest.
pick_target() {
  local agent=$1
  tmux list-panes -t "$agent" -F '#{pane_id} #{pane_left} #{pane_width} #{pane_height}' | awk \
    -v a="$agent" \
    -v al="$(tmux display -p -t "$agent" '#{pane_left}')" -v aw="$(tmux display -p -t "$agent" '#{pane_width}')" '
    $1 == a { next }
    { beside = ($2 + $3 <= al || $2 >= al + aw); score = beside * 1e9 + $3 * $4
      if (score > best) { best = score; id = $1 } }
    END { if (id) print id }'
}

cmd_open() {
  local agent=$1 found tool sid cwd sel answer target window
  if ! found=$(find_session "$(tmux display -p -t "$agent" '#{pane_pid}')"); then
    msg "no Claude Code or Codex session found in this pane"
    exit 0
  fi
  read -r tool sid cwd <<<"$found"
  sel="$state/selection-${agent#%}.txt"
  cat >"$sel"
  if [ ! -s "$sel" ]; then
    msg "nothing selected"
    exit 0
  fi
  window=$(tmux display -p -t "$agent" '#{window_id}')
  local run
  run=$(printf '%q ' "$self" run "$agent" "$tool" "$sid" "$cwd" "$sel")
  answer=$(tmux show -wqv -t "$window" @ask-agent-pane)
  if [ -n "$answer" ] && tmux list-panes -t "$window" -F '#{pane_id}' | grep -qx -- "$answer"; then
    tmux respawn-pane -k -t "$answer" "$run"
    tmux select-pane -t "$answer"
  elif target=$(pick_target "$agent") && [ -n "$target" ]; then
    answer=$(tmux split-window -v -l 60% -t "$target" -P -F '#{pane_id}' "$run")
    tmux set -w -t "$window" @ask-agent-pane "$answer"
  else
    # Alone in the window: an overlay leaves the agent pane's size alone.
    tmux display-popup -E -x R -y 0 -w 45% -h 100% -T ' ask-agent ' "$run"
  fi
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
               --skip-git-repo-check -o "$out" "$prompt" </dev/null >/dev/null ;;
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
  local out="$state/answer-${agent#%}.txt" err="$state/error-${agent#%}.txt"
  trap "tmux select-pane -t '$agent' 2>/dev/null" EXIT
  set -o history  # Up recalls earlier questions in this pane.
  printf '%s%s session %s · empty line closes%s\n\n' "$dim" "$tool" "${sid:0:8}" "$off"
  local lines
  lines=$(wc -l <"$sel")
  head -n 12 "$sel" | sed "s/^/${dim}│ /;s/\$/${off}/"
  [ "$lines" -gt 12 ] && printf '%s│ … (%d more lines)%s\n' "$dim" $((lines - 12)) "$off"

  # Every question is a new fork of the unchanged main session, so a follow-up
  # sees the earlier side questions only through this transcript.
  local label=Question question prompt thread=''
  while :; do
    echo
    # \001 and \002 tell readline the colour codes take no width; without them
    # it misplaces the cursor once the question wraps and the text seems to vanish.
    read -r -e -p $'\001'"$bold"$'\002'"$label>"$'\001'"$off"$'\002 ' question || exit 0
    [ -n "$question" ] || exit 0
    history -s -- "$question"
    prompt=$(printf '%s\n\n<passage>\n%s\n</passage>\n' \
      "This is a side question about a passage from the conversation above, which the user selected in the terminal. Answer only the question, concisely and in plain words. Do not continue the main task and do not change any files." \
      "$(cat "$sel")")
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
  done
}

case ${1:-} in
  open) shift; cmd_open "$@" ;;
  run) shift; cmd_run "$@" ;;
  *) echo "usage: $0 open <pane-id> | run ..." >&2; exit 2 ;;
esac
