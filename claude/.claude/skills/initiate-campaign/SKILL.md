---
name: initiate-campaign
description: >-
  Start or restart an unattended campaign on a SHARED REMOTE BOARD driven by an
  on-board agent — arm a round by writing and delivering the ruling, retiring
  superseded ones, syncing git, starting the watchdog, arming the monitoring
  loop, and confirming work actually began. Startup only. Use on "arm the next
  round", "the round is finished, what's next", when the work involves a
  container, a watchdog, an inbox acknowledgement or board recovery. NOT for a
  campaign driven by orchestration/local-round-loop.py on a local host, where a
  supervisor process schedules rounds and there is no ruling, container or wake
  loop — that is `initiate-loop-campaign`. Ongoing wake-to-wake monitoring is NOT
  here — that is ~/.claude/rules/unattended-campaign.md.
---

# Initiate Campaign — Startup

**Scope: bringing a round into existence and getting the board working on it.** Everything afterwards — the sweep, its questions, the wake prompt's own text, decision authority, escalation — is `~/.claude/rules/unattended-campaign.md`, which governs every wake. This file hands over at step 9 and does not take control back until a round ends. Do not answer "how is the campaign doing" from here; read the rule.

Not duplicated here: `orchestration/docs/NIGHTLY-RUN.md` (watchdog arming, morning triage, signatures worth recognising), `orchestration/CHECKS.md` (which gates are proven versus never-fired), `handoff-work` (when state must cross sessions).

## Discover, never hardcode

Encode the lookup, not the literal — a skill naming last month's container is worse than no skill. Needed twice: to arm, and to fill in the loop prompt's briefing.

| Value | How to find it |
|---|---|
| Campaign directory | `orchestration/campaign-paths.sh` — the single campaign under `investigations/*/campaign` with both `rulings/` and `messages/` |
| Ruling files | `$CAMPAIGN_DIR/rulings/standing-orders.txt` and `current-round.txt`, symlinked into the container |
| Container / board access | `HELIOSR_CONTAINER` and `$HOME/bin/heliosr`, as used by `orchestration/send-message.sh` |
| Agent runtime paths | `orchestration/agent-runtime.sh` (`AGENT_BIN`, session glob, proc pattern) |
| Watchdog config | `orchestration/systemd/heliosr-watchdog.service` |

If a lookup fails, fix the wiring rather than routing around it. A stale symlink will fail again next round; a workaround in your head will not survive compaction.

## Arming a round

Ordered because the dependencies are real.

**1. Establish current state before writing anything.** The live ruling's sha256, the agent's HEAD, what the last round actually closed with, whether cells went unspent. Read the ledger's words, not your memory of them. If the previous round is finished, say so in the new file rather than leaving the agent to infer it.

**2. Write the round.** Rulings **supersede rather than accumulate** — one authorization in force at a time. Before writing a word, read *Say what counts as done, not how to get there* in `~/.claude/rules/unattended-campaign.md`: it governs how much to specify, and it is deliberately not restated here, because two copies of that instruction would drift apart and both would keep reading as authoritative. In short — state what makes a result admissible, never how to produce it, and keep out any sentence a machine event could falsify. House structure:

- Header naming the round and its question, plus the **predecessor sha256**
- A section stating what stands and, explicitly, **what does not** — including claims never actually measured, so the agent cannot inherit an assumption
- The question, and why it is admissible where an earlier attempt was not
- The contract: what is under test, what is held fixed, what may not be compared against what
- Off-hardware **checks that run before any device row**, each with a predicted value and an explicit "FAIL means stop and report, not proceed"
- Device rows, with the controls each claim requires
- Enumerated outcomes (a)…(d) and the sentence each one licenses — written *before* the rows exist
- Safety, stopping conditions, and a **NOT AUTHORIZED** section
- A CONTINUITY block: predecessor hash, and what the prior round left unused

Predeclaring the criteria is what makes the next report a result rather than an argument.

**3. Write gates that stop the claim, not the work.** Re-read the stopping conditions imagining the operator absent. A gate written for a supervised round becomes an idle board at 3am. The right shape stops the comparison, records the refusal, and drops to the next authorized item — reserve true halts for when the machine itself is at risk.

**4. Retire the legacy.** Move obsolete rulings into `rulings/superseded/`; leave `rulings/` holding exactly what the agent is told to read. Amend in place with a dated `AMENDMENT` section rather than editing history — the agent hashes the file and will notice, and an amendment landing after it has read the file needs an explicit "re-read section N" message.

**5. Commit and push.** Pushing the campaign record is standing-authorized (the rule's *Act without asking*) — an unpushed ruling never reaches the container, so this is part of writing it, not a separate decision. On a non-fast-forward: `git fetch`, `git rebase origin/main`, push — the on-board agent pushes to the same branch and will race you. Never force-push, never amend published history, never stash the tree to unblock a rebase; commit the log churn separately.

**6. Deliver, and prove delivery.** Each step has an independent failure mode:

```
push  →  push-agent-context.sh  →  verify the checkout's hash  →  send-message.sh --file  →  --check
```

The agent reads its authoritative checkout, not your working tree — hash-verify the file it will actually read. `--check` must print `UNACKED_COUNT 0`; `UNACKED_UNKNOWN` means the inbox could not be read and **is not zero**. Re-ring a lost doorbell with `--ring ID`; never send a second copy.

**7. Start the watchdog, and prove the right one is running.** `systemctl --user restart`, then confirm a **new PID** carrying the unit's environment. A watchdog started before your config change keeps the old config and holds the singleton lock, so the restart silently stands down and the change appears to have taken effect. If it refuses with "watchdog already running", find what holds the lock file and check whether it is an orphan.

**8. Arm the monitoring loop.** `CronCreate`, session-only unless asked otherwise, on **off-minutes** (`:11,:41`, not `:00,:30`). Mention that recurring jobs auto-expire after 7 days.

You create the job; you do not author what it says. The prompt text is `~/.claude/rules/campaign-wake-prompt.md` — a monitoring artifact, owned by the rule, rendering the rule's question set. Fill its bracketed values from the *Discover, never hardcode* table above and paste the result. Do not compose a wake prompt from scratch here, and do not let its first line invoke this skill: a wake is not startup.

**9. Prove the agent started, then hand over.** Arming is not delivery and delivery is not work. Watch for the heartbeat to name the round's first item; an agent that acked and then sat down is what this step exists to catch. Once it is working, this skill is done.

## Anti-patterns

Startup-specific; the wake-to-wake ones are in the rule.

- Accumulating rulings instead of superseding, leaving two authorizations in force.
- Amending a ruling the agent already read without telling it which section moved.
- Treating the push as the delivery, or arming the loop as the round having started.
- Restarting the watchdog without confirming the PID changed.
- Leaving the previous round's cron job alive beside the new one, so two loops ask different questions.
- Writing a stopping condition that halts the board rather than halting the claim.
- Hardcoding a container name, session path, or hash into the loop prompt instead of discovering it.
