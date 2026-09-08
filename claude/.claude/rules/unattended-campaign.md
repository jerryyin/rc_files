---
globs: "**/triton-investigations/**"
description: Every wake of a long unattended campaign on a shared machine — delegating the sweep, the fixed question set, which of the agent's questions you answer yourself versus escalate, and when to escalate immediately
---

# Unattended Campaign Supervision

**This file governs every wake** — a loop fires, or someone asks how the campaign is doing.

**Startup is not here.** Arming a round, delivering the ruling, starting the watchdog, creating the cron job: that is the `initiate-campaign` skill. When arming ends, this file takes over and does not hand back.

**Monitoring is here in full, including the wake prompt itself.** The skill creates the cron job; what that job *says* is a monitoring artifact and belongs to this file. The fill-in-the-blanks text is [`campaign-wake-prompt.md`](campaign-wake-prompt.md), which renders the question set below — one list, in one place. Two question sets in two files drift apart, and the drift is invisible: both halves keep answering their own questions and both report nominal.

The two failure modes look identical from the operator's chair: the agent is blocked, and the agent is idle because nobody gave it anything to do. The second is the expensive one and it is always the operator's fault. **A quiet board is the alarm, not a quiet night.**

## Delegate the sweep

Launch a subagent to do the status check and any board recovery. Never inline. Your context is reserved for direction: writing rulings, designing gates, deciding what gets measured next, and noticing that a result changes the plan.

The briefing is not a reference — it is the entire world that agent gets. It starts with none of the conversation, so give it the access path, the container, the state files, the standing orders, and the current ruling. Constraints restated inside it are load-bearing, never duplication to be compressed into a pointer it cannot follow.

## Ask the same questions every wake

A fixed set makes drift show up as an unanswerable question instead of a confident wrong answer. Answer each from artifacts, never from the last summary. Each item names both the question and the thing that answers it, because a question with no named artifact gets answered from memory.

1. **Is the agent working, or merely alive?** The heartbeat: has it changed, and does it name something in flight? A live process with a frozen heartbeat is parked. **Flag any two status fields of different vintage** — a stale block surviving beside a refreshed one reads as current and is how a dead boot's state gets quoted back at you.
2. **If parked — what is it waiting for, and whose call is it?** The blocked-on-operator file, quoting only what is new. This is the question the whole loop exists for. Route it through [Decision authority](#decision-authority).
3. **Is anything unacked?** The delivery tool's own check, every wake, without exception — see below. An unknown result is not zero.
4. **Is the machinery up?** Agent process, container, board; watchdog running, one instance, right environment.
5. **Has the boot id changed?** A new boot means a host failure or a reclaim. Rows from different boots are never poolable, and an unmatched launch record identifies the configuration that took the machine down. Where a launcher pins the boot, quote the pin: re-pinning is authorized; deleting the check, downgrading it to a warning, or making it env-overridable is not.
6. **Is the work on the rung the ruling names?** Item by item, in that ruling's own words. Any frozen file modified is an immediate escalation.
7. **Is the record balanced?** The breadcrumb ledger's before / outcome / resolution counts, and any unmatched before-record — an attempt that started and never resolved.
8. **Is work stranded on disk?** Uncommitted artifacts do not survive a host failure; unpushed commits never reach the container.
9. **Does the round still have unspent cells?** If not, arm the next one — see below. **This one is yours and is never delegated**, because its answer authorizes new work; the sweep supplies the evidence, you draw the conclusion.

Report in a few lines when nominal. Do not pad a quiet sweep into a status essay.

## Check for an unacknowledged message every wake

An agent that finished a turn is idle until something wakes it, and from your side that is indistinguishable from an agent that is working. **A ruling is delivered when it is acknowledged, not when you pushed it.** On 2026-08-16 two rulings were committed, pushed, and written to a plausible-looking file, and the board still sat idle — the agent read a different clone, and nothing had rung its doorbell.

Use the campaign's own delivery tool rather than checking by hand; it already hash-verifies that the message landed and lists messages with no receipt. Re-ring a lost doorbell; never send a second copy, because two live copies of one authorization is the state the mechanism exists to prevent.

## Answer the agent

The agent will stop and ask. **Default to answering.** If every question routes to the operator, the campaign runs at the operator's availability, and an absent operator stalls it indefinitely — the exact failure this arrangement exists to prevent.

That includes the awkward case where your own ruling contradicts itself, or sets a bar nothing could clear. That is an authoring defect. Fix it by rewriting the requirement so it still bites, never by waiving it. An agent that stops rather than guess which reading you meant is behaving correctly — the stopped turn is the cost of the defect, and far cheaper than a measurement taken on the wrong reading.

Say plainly that the question is answered and the agent should proceed without waiting further. Ambiguity about whether your reply was an answer or a musing reproduces the block.

## Decision authority

**Answer it yourself, now, and write it down as an amendment or a message.** These are all cases where you are the source of truth:

- What your own ruling meant — how a clause scopes, what an ambiguous word covers, which of two readings you intended.
- A defect in your own ruling: a step nothing could satisfy, or two clauses that disagree.
- What to do first, and what to do while blocked — there is always off-hardware work.
- Whether a result needs an extra comparison run before you will accept what it claims.
- Which of the round's pre-written outcomes a result counts as, and therefore what may now be said about it.
- Whether routine files may be committed. If committing results is already normal practice, say so once as a standing answer instead of re-granting it every time.
- How much to run at once: cap parallelism, build sequentially, report feasibility before starting.

**Act without asking.** These are standing authorizations — waiting on them costs more than getting them slightly wrong:

- **Push the campaign record.** Rulings, amendments, results, logs, breadcrumbs: pushing is how the record exists at all, and an unpushed commit never reaches the container. This is a standing exception to the global "never push without authorization" rule, scoped to this campaign's repo and branch. Rewriting history is still not included — see below.
- **Power cycle when the boot itself is the problem.** Take it once you have established that the fault cannot be cleared inside the current boot — a wedged queue that ignores REMOVE_QUEUE and SIGKILL, a driver that will not reload. Do not cycle merely because the board is unreachable; ssh here fails intermittently, so retry first and get positive evidence the box is down. Cycle *before* spending rows, never after, so nothing measured is stranded on a boot you then discard. And know the cost you are imposing: this board is shared, and a cycle evicts every neighbour's work along with the fault.
- **Spend the time.** Long builds, extra runs, another round of measurement. Slow is fine; idle is not.
- **Follow a root cause out of scope.** Finding out *why* is almost always worth it. Drifting a little from the round's stated path to answer that is a good trade, not a violation — record the deviation and continue.

**Report or escalate** — a smaller list than it looks, and most of it is telling, not asking:

- **A result that changes what the operator may claim.** A report, not a request — send it even when no decision is needed, so they do not learn it late.
- Rewriting history: force-push, amend, rebase over what is already published.
- Loosening a safety rule, a quarantined configuration, or a neighbour-safety constraint.
- Abandoning or redefining the question the campaign exists to answer, or what counts as done. Chasing a root cause is not this; concluding the original question is no longer worth answering is.

**Never, whoever asks:**

- Touch another tenant's processes, files, or allocations.
- Use root for campaign work that does not need it.
- Write to a tree marked read-only.
- Change a file that was frozen as evidence — corrections go in a new file beside it, never inside it.
- Loosen a checker so a result it rejected gets accepted.
- Relaunch the on-board agent yourself when a watchdog owns relaunch.

## Keep the decisions, delegate the observations

The subagent observes and may fix things within already-written policy. It never decides campaign questions — it does not pick what to measure, admit a variant, change a requirement, reinterpret a ruling, or invent authorization. Anything not already answered in writing comes back to you.

Spot-check its report against the authorized direction. The question is "is the board working on the rung it should be on," not "let me verify each number myself." Re-deriving the sweep defeats the delegation.

## Escalate immediately, not on the next wake

Wake the operator the same turn for: work stopped or about to stop; a stopping condition fired; the board unusable; an unacked message in the inbox; a **failed check** — informative, but it changes the round's plan; a result that shows the instrument cannot answer the question; or a decision the rulings do not cover.

**Reporting is not waiting.** Send the report and keep working — remediate, re-plan, take the next authorized item. Only the short escalate list blocks; everything else you tell them about while you continue. A campaign that idles overnight waiting for the next tick has lost the hours that made it unattended work.

## A finished round with no successor is the expensive failure

A blocked agent and a finished round produce the same silence, and only one of them is anyone's fault. Ask every wake whether the live authorization still has unspent work; if not, arm the next round rather than waiting to be asked. Two windows of this campaign expired unused because the round was complete and no successor existed — the operator's gap, not the agent's. Arming is the skill's job; noticing it is due is this file's.

## Anti-drift and anti-patterns

Long campaigns are summarized, and a summary is where a fact quietly becomes an assumption.

- **Re-read the ruling's "what stands and what does not" section each wake.** It is short. Trusting memory over it is how a retired claim gets reused.
- **Verify before recommending** — a remembered path, flag, or hash may be gone.
- **Separate observation from inference,** and name which boot, build, and commit a number came from.
- **A subagent's report is evidence, not truth.**
- Do not re-litigate a decision the operator already made; do not re-audit your own prior turns after correcting one in a line.
- Do not read an unknown or empty unacked result as zero.
- Do not confirm delivery by the fact that you pushed.
- Do not let the sweep keep asking about the previous round's checks — that reports "nominal" while the board sits on nothing.
