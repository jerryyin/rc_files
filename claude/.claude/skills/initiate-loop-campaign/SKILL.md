---
name: initiate-loop-campaign
description: >-
  Stand up or arm a campaign on the local round loop — the supervisor-driven
  arrangement where `orchestration/local-round-loop.py` publishes immutable
  rounds, launches a fresh manager per round, and publishes each next round from
  the previous manager's result. Use on "start a new looped investigation", "set
  up another campaign on the loop", "arm the next run", "run this overnight on
  the local host". NOT for the shared MI450 board with an on-board agent, rulings
  and a wake loop — that is `initiate-campaign`.
---

# Initiate a local-loop campaign

**The procedure lives in the repository, not here:**
`orchestration/docs/NEW-CAMPAIGN.md`. Read it — it is short, it sits beside the
driver it describes, and it changes in the same commit as the driver's CLI. This
file exists to route you there and to establish the few things you must pin down
before following it.

## Which arrangement is this

Check before doing anything, because the two invert who decides what and the
wrong guidance reads as authoritative:

| | Local round loop (**here**) | Shared board (`initiate-campaign`) |
|---|---|---|
| Who schedules the next round | the supervisor, from the last manager's `next_orders` | you, by writing a ruling |
| How orders are delivered | `publish-round` into the state root | commit, push, pull, inbox acknowledgement |
| Monitoring | `wait` and `status` | the wake sweep in `~/.claude/rules/unattended-campaign.md` |
| Recovery | fresh run | watchdog, container relaunch, power cycle |

If the work is on a local host driven by `local-round-loop.py`, you are here.
`investigations/*/AGENTS.md` overrides the repository `CLAUDE.md` inside its own
subtree and will say so.

## Pin these first

Two values, and getting either wrong is silent rather than loud:

- **Campaign root** — `investigations/<campaign>/`. Never discovered. There is no
  singleton lookup on this route; `orchestration/campaign-paths.sh` belongs to
  the other arrangement and will not find a loop campaign at all.
- **State root** — `/root/.local/state/triton-investigations/<campaign>...`. Per
  *run*, not per campaign. A fresh-run recovery abandons the previous root in a
  terminal phase rather than reusing it, so several roots for one campaign
  co-exist and a terminal one reads exactly like a live one. For an already
  running campaign, derive it instead of remembering it:

  ```bash
  pgrep -af 'local-round-loop\.py.*run --run-id' \
    | sed -n 's/.*--state \([^ ]*\).*/\1/p'
  ```

  Empty output means nothing is running, which is an answer, not a failure.

## Building and arming are one flow

If the campaign directory does not exist yet, you are doing both jobs in one
pass, and `NEW-CAMPAIGN.md` covers them in order: what to copy versus what to
write, then `doctor` → mock-profile bootstrap → live publish/arm/start. Do not
skip the mock run to save time on a campaign you just authored — it is where a
malformed schema surfaces, and the alternative is finding out with a paid manager
already running.

If the directory exists and you are only arming the next run, start at `doctor`
in that same file.

Either way the state is established by reading, not by recall: current
`status`, whether a supervisor is already live, and the publication generation
that `--expected-generation` needs.

## What stays yours

The loop advances rounds on its own, so the leverage is entirely in what you
write before it starts:

- `standing-orders.md` — the durable claim boundary. What may be concluded, what
  evidence admits a claim, what a pass does not prove.
- `orders/round-0001.md` — the first question only.

Say what makes a result admissible, never how to produce it, and keep out any
sentence a machine event could falsify — a filename built from a run id, a
prohibition resting on today's state. The manager is at the machine and you are
not. This is the same discipline as *Say what counts as done, not how to get
there* in `~/.claude/rules/unattended-campaign.md`; it is not restated in full
here because two copies would drift and both would keep reading as authoritative.

## Afterwards

There is nothing to schedule and no wake loop to arm. `wait` blocks until the run
is terminal; `status` answers where it is now. Promoting a verified result into
Git is archival review work, not delivery — `publish-round` already delivered the
orders — so it goes through normal staging and review rather than under any
standing push authorization.
