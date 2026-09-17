---
description: Rendering the cron prompt for an unattended campaign monitoring loop — the fill-in-the-blanks template, and why its two halves are written differently. Read when arming or re-arming the loop, not on every wake.
---

# The campaign wake prompt

The artifact that fires a monitoring wake. The doctrine it serves is `unattended-campaign.md`; this file only renders it. Creating the cron job is the `initiate-campaign` skill's step 8 — this is the text that job carries.

Fill the bracketed values by discovery (the skill's *Discover, never hardcode* table), never from memory.

## Its two halves age differently, and that is the whole design

**Stable for the campaign:** access paths, the constraint block, the fixed question set. Hardcode these — a subagent gets nothing but this text, and a constraint compressed into "see the standing orders" is a constraint it cannot follow. Restate; do not reference.

**Volatile between fires:** the live ruling, the current rung, round-specific escalation triggers. **Name none of them.** Make the wake read them instead. A prompt that states the volatile half is correct exactly until the next amendment and then confidently sends a subagent to ask about a superseded ruling — on 2026-09-08 three consecutive wakes fired asking about an amendment that had been superseded an hour earlier, one of them asking whether a result already accepted had been reported. Nothing warns you: a stale sweep answers its questions and reports nominal.

So the prompt's first instruction is to `git log`, read the **last** amendment section of the live ruling, hash it, and compose the briefing from what was just read. Staleness becomes structurally impossible rather than merely discouraged.

**A standing directive about the work is volatile, however permanent it sounds.** The temptation is to carry one in the prompt — "the off-hardware work is X", "no build on thread Y is authorized" — because it reads as policy rather than as a rung. It is not policy. It is the previous round's ordering wearing policy's clothes, and it goes stale on the same clock as everything else. On 2026-09-11 a wake prompt spent a morning telling every sweep that a category of build was unauthorized and that a particular characterization was the work, hours after a hard halt had lifted the first prohibition and declared the second finished. Two sweeps audited against it and both reported nominal. State instead, in the prompt, that the work is whatever the last amendment names, and that **any directive the sweep finds in logs, messages, the roadmap or a heartbeat that conflicts with the last amendment is superseded — including one that sounds like the operator's**. The container accumulates old orders and they all read as current.

**A number and a filename pattern are volatile too, and they go stale silently rather than loudly.** A stale prohibition at least contradicts the ruling when someone reads both. A stale *baseline count* and a stale *file glob* contradict nothing: the sweep compares against the wrong number and reports "unchanged", or globs a pattern that matches nothing and reports "no launchers found", and both read as a clean answer to the question that was actually asked. On this campaign the prompt carried a ledger baseline of 15,055 records for days after the ledger passed 15,127, and a launcher glob of `run-tokenspeed-*` for a family that had been renamed `replay-tokenspeed-*` — every sweep either silently mis-compared or found nothing, and every sweep reported nominal. Neither was ever fixed in the prompt, only corrected by hand in each briefing, which is the same defect surviving by being patched downstream. So: carry no count, no hash and no glob in the prompt. Carry the **command that derives it** and the instruction to compare against what the previous sweep reported, exactly as the frozen-set rollup already does — that one was written as a recompute-and-compare and never went stale.

**Line 1 loads the rule.** A manager wake is a cron prompt you wrote, so it names the governing file rather than hoping an ambient glob loads it. Do not make line 1 invoke the skill: the skill is startup, and a wake is not startup.

## Template

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
  wrapper form, and say explicitly that a bare local exec does not work]. [Whether the
  transport is flaky, and that it must be retried before anything is called down.] An
  unreadable answer is NOT a zero answer. Repos: [local path] and [the agent's authoritative
  checkout inside the container].

  FIXED QUESTIONS, every wake -- answer each from artifacts, and keep it SHORT:
  1. [heartbeat file] -- what is in flight, and its timestamp. Flag if older than [the
     standing order's interval]. Flag any two status fields of different vintage.
  2. [blocked-on-operator file] -- quote only content new since the last sweep.
  3. `bash orchestration/send-message.sh --check` -- UNACKED_COUNT and any unacked ids
     verbatim. UNACKED_UNKNOWN is NOT zero.
  4. Agent process alive? Container up? Board reachable? [watchdog unit] running, exactly one
     instance?
  5. Has the boot id changed? Where the ruling gates a launcher on a boot-id or envelope
     check, grep the launcher and QUOTE the lines: re-pinning is authorized; deleting it,
     downgrading it to a warning, or adding an env override is FORBIDDEN. Report which id is
     pinned, and any device row taken, with its id.
  6. Progress against the CURRENT ruling's authorized order, item by item, in the words that
     ruling uses. [Name the frozen files: any modification is an immediate escalation.]
  7. [breadcrumb ledger] balance -- before / outcome / resolution counts, unmatched records.
  8. Device contention: do we hold the lock? FOREIGN count (say "unreadable" if it cannot be
     read -- unreadable is not zero)?
  9. Stranded work: uncommitted paths or unpushed commits in [both checkouts]. Report only --
     do not fix, commit, stage or reset.

  MAY REMEDIATE within already-written policy: nothing more. It must NOT decide campaign
  questions -- no selecting a cell, admitting a variant, changing a gate, reinterpreting a
  ruling, or inventing authorization. Anything not already answered in writing comes back
  UNANSWERED.

  HARD CONSTRAINTS: [neighbour-safety rule, with the number of tenants sharing the machine].
  [any quarantined configuration]. [read-only trees]. Never run `git checkout <ref> -- .` or
  anything that stages/resets/stashes/discards a working tree; read remote files with
  `git show <ref>:<path>`. Do not relaunch the agent directly (the watchdog owns that). Do not
  power cycle. Do not launch GPU work. Do not use root for campaign work. This is a READ-ONLY
  sweep: modify nothing.

  Separate OBSERVED from INFERRED.

When the subagent reports back: spot-check it against the ruling you read at the top of this
turn, rather than re-deriving its observations. The question is "is the board on the rung the
live ruling names" -- and the answer comes from that file, not from this prompt.

ESCALATE TO ME IMMEDIATELY, same turn, if: work has stopped or is about to; a stopping
condition fired; the board is unusable; a message is sitting unacked; a boot-id or envelope
check was removed, weakened or overridden rather than re-pinned; a frozen file was modified;
any figure pools rows across two boots; a gate the live ruling declared FAILED; the live
ruling's cells are all spent and no successor exists (arm one -- a finished round and a
blocked agent produce identical silence); or a decision has come up that the written rulings
do not cover. Reporting is not waiting: send it and keep working.

If everything is nominal and unchanged, say so in one or two lines. Do not pad the report.
```

## The ninth question is not delegated

The rule's *Does the round still have unspent cells?* is missing from the briefing on purpose. Its answer authorizes new work, so it is the operator's and never a subagent's — see *Keep the decisions, delegate the observations*. The sweep supplies the evidence; the operator draws the conclusion and arms the successor.

## Re-arm when the *stable* half changes

Because the prompt reads the ruling at every fire, a new round or amendment needs no new job — that was the point of moving the volatile half into a discovery step. Re-arm only when the stable half moves: a different container, a relocated repo or ruling path, a changed constraint, a question worth adding to the fixed set. Then fold the change back here, so the next campaign starts from the improved text rather than rediscovering it.

Delete the old job first. Two loops asking different questions is worse than one asking stale ones, because the answers disagree and both look authoritative.
