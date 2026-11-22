#!/usr/bin/env bash
# Question loop of the ask-agent pane, shared by Linux tmux and Windows psmux.
#
#   ask-agent-chat.sh <source-pane> <passage-file> <tool> <session-id> <cwd>
#   ask-agent-chat.sh <source-pane> <passage-file> -- <resolver> [args...]
#
# <tool> is claude or codex. A resolver is run on the first question, on the
# pane's terminal so it can ask the user; it prints "<tool>\t<session-id>\t<cwd>",
# or nothing to close the pane. The passage file and any file named
# <passage-file>.* are deleted on exit. Each question runs in a temporary fork of
# the session; the original conversation is not changed.
set -u
umask 077
export PATH="$HOME/.local/bin:$PATH"

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

chat() {
  local agent=$1 sel=$2 tool='' sid='' cwd='' resolver=()
  shift 2
  if [ "${1:-}" = -- ]; then
    resolver=("${@:2}")
  else
    tool=$1 sid=$2 cwd=$3
  fi
  local dim=$'\e[2m' bold=$'\e[1m' off=$'\e[0m'
  local out="$sel.answer" err="$sel.error"
  trap 'rm -f -- "$sel" "$sel".*; tmux select-pane -t "$agent" 2>/dev/null' EXIT
  local passage line lines=0
  passage=$(<"$sel")
  rm -f -- "$sel"
  set -o history  # Up recalls earlier questions in this pane.
  local heading='Ask about this selection'
  [ -n "$tool" ] && heading="$tool session ${sid:0:8}"
  printf '%s%s · empty line closes%s\n\n' "$dim" "$heading" "$off"
  while IFS= read -r line; do
    (( ++lines ))
    (( lines <= 12 )) && printf '%s│ %s%s\n' "$dim" "$line" "$off"
  done <<<"$passage"
  (( lines > 12 )) && printf '%s│ … (%d more lines)%s\n' "$dim" "$((lines - 12))" "$off"

  # Every question is a new fork of the unchanged main session, so a follow-up
  # sees the earlier side questions only through this transcript.
  local label=Question question prompt session thread=''
  while :; do
    echo
    # \001 and \002 tell readline the colour codes take no width; without them
    # it misplaces the cursor once the question wraps and the text seems to vanish.
    read -r -e -p $'\001'"$bold"$'\002'"$label>"$'\001'"$off"$'\002 ' question || exit 0
    [ -n "$question" ] || exit 0
    if [ -z "$tool" ]; then
      session=$("${resolver[@]}") || continue
      [ -n "$session" ] || exit 0
      IFS=$'\t' read -r tool sid cwd <<<"$session"
      printf '%s%s session %s%s\n' "$dim" "$tool" "${sid:0:8}" "$off"
    fi
    history -s -- "$question"
    prompt=$(printf '%s\n\n<passage>\n%s\n</passage>\n' \
      "This is a side question about a passage from the conversation above, which the user selected in the terminal. Answer only the question, concisely and in plain words. Do not continue the main task and do not change any files." \
      "$passage")
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

chat "$@"
