# Composing the monitoring-loop prompt

Arming step 8. This is the last startup artifact — from the moment the job fires, `~/.claude/rules/unattended-campaign.md` is in charge and this skill is not consulted again until a round ends.

**Line 1 loads the rule.** That is the deterministic trigger: a manager wake is a cron prompt you wrote, so the prompt names the file that governs the wake instead of hoping an ambient glob or a remembered habit loads it. The project `CLAUDE.md` pointer and the rule's `globs` are the second and third nets, for entry that does not come through the loop. Do **not** make line 1 invoke this skill — the skill is startup, and a wake is not startup.

**The constraint block inside the briefing is deliberate, and is not duplication to be cleaned up.** The subagent gets nothing but this text. A constraint compressed into "see the standing orders" is a constraint that agent cannot follow. Restate; do not reference.

**Name no round, rung or amendment in the prompt itself — make the wake turn read them.** The two halves of this prompt age differently. Access paths, the constraint block and the fixed question set are stable for the whole campaign; the live ruling, the current rung and the round-specific escalation triggers change under it, sometimes several times between two fires. A prompt that states the volatile half is correct exactly until the next amendment, and then confidently sends a subagent to ask about a superseded ruling — on 2026-09-08 three consecutive wakes fired asking about an amendment that had been superseded an hour earlier, one of them asking whether a result already accepted had been reported. Nothing warns you: a stale sweep answers its questions and reports nominal.

So the prompt's first instruction is to `git log`, read the **last** amendment section of the live ruling, and hash it — and then compose the briefing from what was just read. Hardcode the stable half, discover the volatile half. Same rule as the skill's *Discover, never hardcode* table, applied to the round rather than to the container name, and it makes staleness structurally impossible rather than merely discouraged by [the re-arm note below](#re-arm-the-prompt-when-the-round-changes).

Fill the bracketed values by discovery (the SKILL's *Discover, never hardcode* table), not from memory. Schedule on off-minutes — `11,41 * * * *` rather than `0,30` — so the job does not land on the same instant as every other scheduled job on the planet. Session-only unless the user asks for durable. Recurring jobs auto-expire after 7 days; say so when you arm one.

---

```
Read ~/.claude/rules/unattended-campaign.md and follow it for this wake — campaign
supervision sweep for the on-board agent in [container]. DELEGATE this sweep to a subagent,
do not perform it inline. Your context is reserved for direction, not observation.

FIRST, before writing the briefing, establish the live state yourself — not from this prompt,
not from memory, not from a prior summary. This prompt deliberately names no round, rung or
amendment, because every earlier version of it went stale between fires:

  cd [local repo]
  git log --oneline -5
  tail -120 [ruling path]/current-round.txt
  sha256sum [ruling path]/current-round.txt

The LAST amendment section is the live one; anything it supersedes is dead. Read its "what
stands and what does not" and its authorized ordering. That ordering — not this prompt — is
the rung the board should be on.

THEN write the subagent briefing from what you just read (it starts with none of our
conversation):

  ACCESS: [how to reach the board and how to exec inside the container -- give the exact
  wrapper form, and say explicitly that a bare local exec does not work]. Repo: [local path]
  and [the agent's authoritative checkout inside the container].

  REPORT, in this order, and keep it SHORT:
  1. [heartbeat file] -- what is in flight, and has it changed since the last sweep?
     Flag it if the timestamp is older than [the standing order's interval].
  2. Is the agent process alive? Is the container up? Is the board reachable?
  3. `bash orchestration/send-message.sh --check` -- report UNACKED_COUNT and any unacked ids.
     UNACKED_UNKNOWN is NOT zero.
  4. [blocked-on-operator file] if present and newer than the last sweep.
  5. [breadcrumb ledger] balance -- before / outcome / resolution counts, unmatched records.
  6. Progress against the CURRENT ruling's authorized order, item by item, in the words that
     ruling uses. Where the ruling gates a launcher on a boot-id or envelope check, grep the
     launcher and quote the lines: re-pinning is authorized, deleting it, downgrading it to a
     warning or adding an env override is FORBIDDEN. Report which boot id is pinned, and any
     device row taken, with its boot id.
  7. Device contention: do we hold the lock? FOREIGN count (say "unreadable" if it cannot be
     read -- unreadable is not zero)?
  8. Stranded work: uncommitted paths or unpushed commits in either checkout. Report only --
     do not fix, commit or reset.

  MAY REMEDIATE within already-written policy: nothing more. It must NOT decide campaign
  questions -- no selecting a cell, admitting a variant, changing a gate, reinterpreting a
  ruling, or inventing authorization. Anything not already answered in writing escalates.

  HARD CONSTRAINTS: [neighbour-safety rule]. [any quarantined configuration]. [read-only
  trees]. Never run `git checkout <ref> -- .` or anything that stages/resets/stashes a working
  tree; read remote files with `git show <ref>:<path>`. Do not relaunch the agent directly
  (the watchdog owns that). Do not power cycle. Do not use root for campaign work.

When the subagent reports back: spot-check it against the ruling you read at the top of this
turn, rather than re-deriving its observations. The question is "is the board on the rung the
live ruling names" -- and the answer comes from that file, not from this prompt.

ESCALATE TO ME IMMEDIATELY, same turn, if: work has stopped or is about to; a stopping
condition fired; the board is unusable; a message is sitting unacked; a boot-id or envelope
check was removed, weakened or overridden rather than re-pinned; any figure pools rows across
two boots; a gate the live ruling declared FAILED; the live ruling's cells are all spent and
no successor exists (arm one -- a finished round and a blocked agent produce identical
silence); or a decision has come up that the written rulings do not cover. Reporting is not
waiting: send it and keep working.

If everything is nominal and unchanged, say so in one or two lines. Do not pad the report.
```

---

## Re-arm the prompt when the *stable* half changes

Since the prompt reads the ruling at every fire, a new round or a new amendment no longer needs a new job — that was the whole point of moving the volatile half into a discovery step. Re-arm when the stable half moves: a different container, a relocated repo or ruling path, a changed constraint, a question worth adding to the fixed set.

When you do re-arm, delete the old job first. Two loops asking different questions is worse than one asking stale ones, because the answers disagree and both look authoritative.

A sweep still asking about a superseded ruling is how a loop reports "nominal" while the board sits on nothing — the same failure as a stale relaunch message re-issuing a withdrawn plan once per boot. Re-arming is a startup action, so it comes back here; noticing that the *round* is spent happens during monitoring and belongs to the rule.
