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
  wrapper form, and say explicitly that a bare local exec does not work]. [Where the remote
  prints a LOGIN BANNER, the exec form ends in a `tail -N` to cut it -- so say that tail cuts
  the TOP of the sweep's OWN output too, and that the payload must put the values it most
  needs at the END. A sweep that batches ten reads and tails the last forty lines silently
  loses the first six, and what it does print looks complete.] [Where the wrapper
  RESOLVES A ROUTE from several candidates, PIN IT and say why pinning is not cosmetic: a
  transport hiccup on the first candidate makes it FALL THROUGH to a candidate that fails
  authentication, and the error it then surfaces is an auth error, which reads as a dead
  board when the board is fine. On 2026-09-09 that produced twenty minutes of "link still
  down" and "container is not running ()" against a container that was Up 4 hours. Give the
  env var and the value.] [Whether the
  transport is flaky, and that it must be retried before anything is called down. Name its
  DISTINCT failure signatures separately and say what each does NOT mean -- an auth failure
  that a healthcheck reads as NO_ACCESS is not "the agent is gone", and a host that refuses
  a connection seconds after answering one is not "the board is down". A failure in the host's
  USER-DIRECTORY LOOKUP wears the costume of a dead board and is neither: on 2026-09-10 the
  out-of-band route reached the host fine while sudo answered "unknown user <name>" and "you do
  not exist in the passwd database", concurrent with the wrapper reporting a transport fault.
  Nothing was wrong with the board or the agent, and it cleared on retry within three minutes.
  Say that an identity lookup failing is a fault in the HOST'S NAME SERVICE, that it can arrive
  alongside a genuine probe failure and be mistaken for its cause, and that it must not be
  reported as the board being down or the agent being gone.] An unreadable answer
  is NOT a zero answer -- and name any way the transport can return an EMPTY RESULT WITH A
  SUCCESS CODE, because every retry rule keys on failure and will not fire. [On this campaign:
  piping stdin through the wrapper yields empty with exit 0 -- stdin does not traverse it. Give
  the working form instead (base64 the payload into the command string), and say that a sweep
  which used the piped form may have read nothing and reported it as clean. This bites WRITES
  as well as reads: on 2026-09-09 the context pusher and the message sender both wrote files
  into the container by redirecting into a remote `cat`, so both wrote ZERO BYTES and logged
  "pushed" -- the container's relaunch script sat empty for hours, which is the one path the
  watchdog has for recovery. Have the sweep hash what it wrote, and treat sha256 of the empty
  string, e3b0c44298fc..., as a signature worth recognising on sight. The same empty-with-
  success hash arrives by a second route: `docker cp` of a file that is a SYMLINK copies the
  link, not the target, and yields zero bytes -- on 2026-09-09 a sweep read the live ruling
  that way and fabricated an empty-file crisis out of a healthy file. Use `docker cp -L`.]
  [Where the transport gates on a pinned boot id: say that a STALE PIN and a DEAD LINK are
  indistinguishable from the caller's side, and that the wrapper may actively mislabel its own
  gate refusal as a transport fault. Give the out-of-band route that bypasses the gate and
  reads the boot id directly, and require it before any "the board is down" claim -- on
  2026-09-09 a reboot was read as forty minutes of flaky link because the refusal said
  "This is a TRANSPORT fault and not a statement about the board" and was wrong about itself.]
  Repos: [local path] and [the agent's authoritative checkout inside the container -- give the
  lookup, not the literal path].

  FIXED QUESTIONS, every wake -- answer each from artifacts, and keep it SHORT:
  1. [heartbeat file] -- what is in flight, and its timestamp. Flag if older than [the
     standing order's interval]. Flag any two status fields of different vintage.
  2. [blocked-on-operator file] -- quote only content new since the last sweep.
  3. `bash orchestration/send-message.sh --check` -- UNACKED_COUNT and any unacked ids
     verbatim. UNACKED_UNKNOWN is NOT zero. [Where a question has a PERSISTENT KNOWN FALSE
     POSITIVE, name the exact id or signature and say what count is nominal WITH it present.
     Do not leave it to be rediscovered each wake: an anomaly that every sweep reports and
     every sweep dismisses stops being read, and the real one arrives wearing its clothes.
     On this campaign an acknowledgement addendum whose filename ends in `.md` is counted as
     an unacked message forever, so UNACKED_COUNT 1 consisting solely of that id is nominal
     and anything else is not.] And where the agent can be asleep, parked or
     winding down, a receipt is not a read: an id that goes unacked-to-acked within seconds
     of a send to a parked agent must be checked against the ack artifact itself, and against
     the ack pattern of a message it demonstrably read while awake, before the ruling is
     called delivered. And check that the message file EXISTS at all: this tool counts *.md
     files lacking a *.ack, so an inbox holding no .md for the id reports UNACKED_COUNT 0 --
     an empty set, not a delivery. On 2026-09-09 a ruling was written empty, failed its own
     hash check, was deleted by the tool's mismatch branch, and read out as a clean zero.
     Require the .md and the .ack as artifacts; a count is not a receipt. [Give the ack
     artifact's EXACT name -- looking for `<id>.md.ack` when the tool writes `<id>.ack`
     returns "no such file" on a perfectly healthy inbox.]
     A SEND REPORTING "DELIVERY UNKNOWN" MUST BE RESOLVED AGAINST THE INBOX, not left as
     probably-landed. Unknown is not a confirmed failure, which is a reason to check and not
     a reason to assume: the tool's own hash-mismatch branch DELETES the file it could not
     verify, so a failed send leaves no .md, no .ack and no trace anywhere except the absence
     itself -- and the count then reads clean. On 2026-09-11 a message carrying an
     authorization for what the agent was permitted to claim sat undelivered for forty
     minutes behind exactly this, while the operator, having announced he would not send a
     second copy, declined to look. Where an id has ZERO copies, sending is a FIRST copy and
     the never-send-twice rule does not bite: that rule exists to prevent two live copies of
     one authorization, and it is not a reason to leave the board with none.
     An id unacked while the agent is ALIVE AND TAKING TURNS is a different fault from one
     unacked on a parked or dead agent, and it is the worse of the two: a session drains
     queued input only when a turn ENDS, so an agent looping on tool calls defers every
     message indefinitely and re-ringing only adds lines nobody will read. On 2026-09-10
     that idled the board for an hour while every delivery check reported healthy. Report
     the id, the agent's session-file mtime and whether new tool calls are being spawned,
     so the operator can tell "has not got to it yet" from "cannot get to it".
  4. Agent process alive? Container up? Board reachable? [watchdog unit] running, exactly one
     instance? [Name any detector known to false-positive, and require a cross-check against
     the real PID and its start time before its verdict is believed. Note that a same-PGID
     child subshell of the watchdog is not a second instance -- compare PPID before calling
     a duplicate. A `pgrep -f <agent>` whose OWN command string contains the pattern matches
     itself, so it reports an agent that does not exist; cross-check tmux or a real PID. The
     detector can false-positive in BOTH directions and did so twice on 2026-09-09.]
     [Say WHICH HOST the watchdog unit runs on. A sweep that looks for it on the wrong
     one finds nothing and reports the recovery path unverifiable -- on 2026-09-09 a
     sweep searched the board host for a unit that is a `systemctl --user` service on
     the OPERATOR host, checked both `list-units` and `list-unit-files`, and correctly
     found zero. That is SCOPE, NOT FAULT, and it is the same shape as the contention
     probe in question 8. Name the host and the `--user` scope so the check runs where
     the unit lives.]
     Also verify the watchdog's RECOVERY PATH is operational rather than merely present:
     its relaunch script and runtime profile non-empty (report byte counts), executable and
     `bash -n` clean. A watchdog that is running and cannot relaunch looks identical to a
     healthy one until the hour you need it.
     And check the recovery path END TO END, not just its scripts: where the watchdog
     recovers the container BY CALLING THE SAME IDENTITY-GATED WRAPPER the sweep reaches
     the board through, that gate can refuse the one command that would fix things. On
     2026-09-10 the wrapper required the container to be RUNNING before it would accept a
     route as ours, and the watchdog's recovery step is `heliosr "docker start <container>"`
     -- so after a reboot left the container Exited, the command to start it was refused
     BECAUSE it was stopped, and the refusal arrived wearing the transport-fault sentence.
     The watchdog logged NO_ACCESS and correctly took no action, forever. Report whether a
     STOPPED container is still reachable through the wrapper, not merely whether a running
     one is; those are the same check only while nothing has gone wrong. A liveness
     condition sitting inside an IDENTITY check is the shape to look for.
  5. Has the boot id changed? READ IT TWICE -- once at the start and AGAIN immediately
     before writing the report, and say both readings with their times. A sweep is long
     enough to straddle a reboot: on 2026-09-09 a sweep read the boot id early, the host
     rebooted mid-sweep, and it reported "boot unchanged, no collision" about a boot that
     had been dead for fifteen minutes. That is the same two-fields-of-different-vintage
     fault question 1 warns about, landing on the sweep's own output. Any answer older
     than the report is a claim about the past stated in the present tense.
     Where the ruling gates a launcher on a boot-id or envelope
     check, grep the launcher and QUOTE the lines: re-pinning is authorized; deleting it,
     downgrading it to a warning, or adding an env override is FORBIDDEN. Report which id is
     pinned, and any device row taken, with its id. [Where run ids, plan files or launchers
     are NAMED for the boot, say so: a boot change kills that whole artifact set, and any
     operator prohibition written against regenerating it ("the plans are correct, do not
     touch them") collides head-on with the new envelope. Report the collision; do not
     resolve it -- that is the operator's, and the resolution is to rewrite the prohibition
     so it still bites, never to waive it.]
  6. Progress against the CURRENT ruling's authorized order, item by item, in the words that
     ruling uses. [Name the frozen files: any modification is an immediate escalation.]
     [PIN THE FROZEN SET WITH ONE ROLLUP DIGEST, and give the command that recomputes it,
     rather than listing digests in this prompt. A prompt can only carry a handful, so a
     sweep asked to confirm "the frozen evidence" for a set of any size falls back to "no
     commit has touched this since the round that produced it" -- which is evidence about
     HISTORY, not about the bytes on disk now, and it reads in a report exactly like the
     stronger check. Hash the sorted (sha256, path) list of the whole set into one number,
     pin it in a file beside the ruling, and have the sweep recompute and compare that.
     Self-test the command before shipping it, and make sure the manifest's own name does
     not match the set's pattern or it perturbs the number it publishes. Say in the pin that
     a mismatch is a QUESTION and not a verdict: a legitimately added file matching the same
     name pattern moves the rollup too.]
     [WHERE A CHECKER WAS JUST CHANGED, that diff is the highest-value thing in the sweep --
     name it and say what must NOT have moved beside the authorized change. "I only fixed
     the band" and "I fixed the band and widened a threshold" produce identical summaries.
     Require the thresholds quoted back, and require that a REFUSAL did not quietly become
     a warning: a guard can fail closed on the value and open on its absence, which emits
     nothing and reads as a pass.]
  7. [breadcrumb ledger] balance -- before / outcome / resolution counts, unmatched records.
  8. Device contention: do we hold the lock? FOREIGN count (say "unreadable" if it cannot be
     read -- unreadable is not zero)? [Where the contention probe is known to under-report,
     say so and require FOREIGN=0 to be reported as weak evidence rather than as "clear" --
     on 2026-09-08 a FOREIGN=0 was recorded while a GPU-attached foreign process was in fact
     resident, and a bracket argument had already been built on it. And check whether the
     probe EXITS 0 ON ITS OWN ERRORS -- this one does, on "cannot resolve the target container
     init PID" -- so a caller keying on exit status reads a failure as a success. Read the
     probe's text, not its status. Note also which SCOPE it must run in: one that fails from
     the operator's host and passes on the board host is scope, not fault.]
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
