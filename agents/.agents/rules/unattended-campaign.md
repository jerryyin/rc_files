# Unattended Campaign Supervision

Applies when: Starting or checking a shared remote-board campaign with an on-board agent, inbox acknowledgements, and a watchdog. Do not apply this to a local-round-loop.py campaign or an unrelated repository.

**Scope: the shared remote board with an on-board agent** — rulings, an inbox, a watchdog, board recovery, a wake loop where *you* are the scheduler. A campaign driven by `orchestration/local-round-loop.py` on a local host is not this and needs none of it: a supervisor process publishes each next round from the previous manager's result, monitoring is `wait` and `status`, and the startup procedure is the `initiate-loop-campaign` skill. Check which arrangement you are in before reading further; the two invert who decides what, so this file applied to the wrong one is confidently wrong.

**This file governs every wake** — a loop fires, or someone asks how the campaign is doing. Startup is not here: arming a round, delivering the ruling, starting the watchdog and creating the cron job belong to the `initiate-campaign` skill, which hands over when arming ends and does not take control back.

This rule owns the supervision requirements. The initiating skill creates the monitoring job using its `~/.agents/skills/initiate-campaign/references/wake-prompt.md` template, which renders the question set below. Keep changes to the questions and their template consistent; read the template only when creating or rearming a job.

The two failure modes look identical from your chair: the agent is blocked, and the agent is idle because nobody gave it anything to do. The second is the expensive one and it is always your fault. **A quiet board is the alarm, not a quiet night.**

## Delegate the sweep, keep the decisions

Use a read-only subagent for the status check when the current agent supports delegation and the task authorizes it. Otherwise perform the same bounded observation inline and state that delegation is unavailable. Board recovery remains subject to the task contract. Keep direction separate from observations: decide what gets measured next only after inspecting the evidence.

Its briefing is not a reference, it is the entire world that agent gets. It starts with none of the conversation, so restate the access path, container, state files, standing orders and current ruling in full. A constraint compressed into a pointer is a constraint it cannot follow.

It observes, and may fix things within already-written policy. It never decides campaign questions — never picks what to measure, admits a variant, changes a requirement, reinterprets a ruling or invents authorization; anything not already answered in writing comes back to you. Spot-check its report against the authorized direction instead of re-deriving its numbers, which defeats the delegation. **A subagent's report is evidence, not truth.**

## Ask the same questions every wake

A fixed set makes drift surface as an unanswerable question instead of a confident wrong answer. Answer each from artifacts, never from the last summary — a question with no named artifact gets answered from memory.

1. **Is the agent working, or merely alive?** The heartbeat: has it changed, and does it name something in flight? A live process with a frozen heartbeat is parked. **Flag any two fields of different vintage** — a stale block beside a refreshed one reads as current, and is how a dead boot's state gets quoted back at you.
2. **If parked, what is it waiting for and whose call is it?** The blocked-on-operator file, quoting only what is new. This is the question the whole loop exists for; route it through [Decision authority](#decision-authority).
3. **Is anything unacked?** The delivery tool's own check, every wake without exception — see below. An unknown result is not zero.
4. **Is the machinery up?** Agent process, container, board; watchdog running, one instance, right environment — and its relaunch path non-empty and syntactically sound, because a watchdog that cannot relaunch looks exactly like one with nothing to do.
5. **Has the boot id changed?** A new boot means a host failure or a reclaim. Rows from different boots are never poolable, and an unmatched launch record identifies the configuration that took the machine down. Quote every boot pin: re-pinning is authorized; deleting the check, downgrading it to a warning or making it env-overridable is not. **Re-pin before diagnosing anything else** — from the caller's side a stale pin and a dead link are indistinguishable, and the wrapper will blame the link.
6. **Is the round closer to its acceptance criteria?** What evidence would answer its question, and how much of it now exists — not whether the agent is taking the steps you pictured, because a well-written round contains none. Measuring conformance instead of progress reports a healthy board as off-track and an off-track board as healthy. A frozen file modified is an immediate escalation.
7. **Is the record balanced?** The ledger's before / outcome / resolution counts, and any before-record that never resolved.
8. **Is work stranded on disk?** Uncommitted artifacts do not survive a host failure; unpushed commits never reach the container.
9. **Does the round still have unspent work?** **Yours, never delegated** — the answer authorizes new work, so the sweep supplies evidence and you draw the conclusion. If nothing is left, arm the next round rather than waiting to be asked: a blocked agent and a finished round produce identical silence, and two windows of this campaign expired unused because no successor existed.

Report in a few lines when nominal. Do not pad a quiet sweep into a status essay.

**On the third question, without exception.** An agent that finished a turn is idle until something wakes it, and from your side that is indistinguishable from working. **A ruling is delivered when it is acknowledged, not when you pushed it** — on 2026-08-16 two rulings were committed, pushed and written to a plausible-looking file while the board sat idle, because the agent read a different clone and nothing had rung its doorbell. Use the campaign's delivery tool, which hash-verifies the landing and lists messages with no receipt. Re-ring a lost doorbell; never send a second copy, because two live copies of one authorization is the state the mechanism exists to prevent.

## Say what counts as done, not how to get there

- **Yours, written before the work exists:** the question, what evidence answers it, what each outcome licenses you to say, which controls a comparison needs, what a pass does *not* prove, the safety and stopping conditions. That predeclaration is why an unattended night yields a result instead of an argument — never loosen it, never shorten a round by cutting it.
- **Not yours, and do not write it at all:** file names, build order, which artifact to copy, whether a value may be re-pinned. The agent is at the machine and you are not.
- **Keep out anything the machine can change under you** — boot and run identifiers, filenames built from them, prohibitions resting on a fact that is true today. They become orders the agent can neither obey nor pass, and it stops.
- **Judge a round on its acceptance criteria, not its middle progress** — with one counterweight: before spending scarce shared resource, the agent says what it will run and what it expects, and you answer fast. One exchange, not a specification.
- **Cap the length.** Every addition must then be paid for by cutting something. Require an amendment to *replace* the section it changes, never append after it. A round that will not fit on a page is usually specifying method.

## Answer the agent

The agent will stop and ask. **Default to answering.** If every question routes to you, the campaign runs at your availability and an absent operator stalls it indefinitely — the exact failure this arrangement exists to prevent. Say plainly that the question is answered and it should proceed without waiting further; ambiguity about whether your reply was an answer or a musing reproduces the block.

That includes the awkward case where your own ruling contradicts itself or sets a bar nothing could clear. That is an authoring defect: rewrite the requirement so it still bites, never waive it. An agent that stops rather than guess which reading you meant is behaving correctly — the stopped turn is the cost of the defect, and far cheaper than a measurement taken on the wrong reading.

## Decision authority

**Answer it yourself, now, and write it down as an amendment or a message.** You are the source of truth for:

- What your own ruling meant — how a clause scopes, which of two readings you intended.
- A defect in your own ruling: a step nothing could satisfy, or two clauses that disagree.
- What to do first, and what to do while blocked — there is always off-hardware work.
- Whether a result needs an extra comparison run before you accept what it claims.
- Which pre-written outcome a result counts as, and therefore what may now be said.
- How to prepare routine files for review. The shared AGENTS.md governs Git actions; commit or push still requires explicit authorization in the current user turn.
- How much to run at once: cap parallelism, build sequentially, report feasibility first.

**Act within the current task contract** — this rule grants no additional Git, recovery, or resource authority:

- **Prepare the campaign record.** Stage and review rulings, amendments, results, logs, and breadcrumbs. Commit or push only when explicitly requested in the current user turn. If publication is required for delivery and authority is absent, report that boundary after preparing the concrete result.
- **When explicitly authorized, power cycle if the boot itself is the problem** — a wedged queue that ignores SIGKILL, a driver that will not reload. Not merely because the board is unreachable: this link fails intermittently, so retry first and get positive evidence the box is down. Cycle *before* spending rows, never after, so nothing measured is stranded on a boot you then discard. The board is shared and a cycle evicts every neighbour's work along with the fault.
- **Use the authorized time and resources.** Keep working on admitted tasks; confirm long builds or additional resource use when the current task contract requires it.
- **Report a root cause that leads outside the agreed scope.** Continue independent in-scope work and obtain the needed scope or resource decision before consequential new work.

**Report or escalate**, most of which is telling rather than asking:

- **A result that changes what may be claimed** — a report, not a request; send it even when no decision is needed, so they do not learn it late.
- Rewriting history: force-push, amend, rebase over what is published.
- Loosening a safety rule, a quarantined configuration, or a neighbour-safety constraint.
- Abandoning or redefining the question the campaign exists to answer. Chasing a root cause is not this; concluding the original question is not worth answering is.

**Never, whoever asks:** touch another tenant's processes, files or allocations; use root for campaign work that does not need it; write to a read-only tree; change a file frozen as evidence, since corrections go beside it and never inside it; loosen a checker so a result it rejected gets accepted; relaunch the on-board agent yourself when a watchdog owns relaunch.

## Escalate immediately, not on the next wake

Wake the operator the same turn for: work stopped or about to stop; a stopping condition fired; the board unusable; an unacked message in the inbox; a **failed check**, which is informative but changes the round's plan; a result showing the instrument cannot answer the question; or a decision the rulings do not cover.

**Reporting is not waiting.** Send it and keep working — remediate, re-plan, take the next authorized item. Only that short list blocks. A campaign that idles overnight waiting for the next tick has lost the hours that made it unattended work.

## Anti-drift

Long campaigns are summarized, and a summary is where a fact quietly becomes an assumption.

- **Re-read the ruling's "what stands and what does not" each wake.** It is short. Trusting memory over it is how a retired claim gets reused.
- **Audit your own drift, not just the agent's.** Ask whether the live ruling has picked up a sentence a machine event could falsify, or an instruction about method rather than about what counts as done. Specificity accumulates one well-meant amendment at a time, and you are the one who will not notice: the agent re-reads the rulings in full at every relaunch, while you work from a summary of a summary.
- **Verify before recommending** — a remembered path, flag or hash may be gone.
- **Separate observation from inference,** and name which boot, build and commit a number came from.
- **Before believing a report that a repair "did not fire", check which version was loaded in the process that ran.** A long-running script is read at launch, so a fix committed while it runs is simply absent from it, and the old quiet behaviour is what the log shows. The report and a real bug look identical, and the report arrives with a line number that resolves against your edited copy — which is what makes it convincing. On 2026-09-11 a sweep correctly observed that a new loud warning stayed silent on the very case it was written for, and inferred the branch was unreachable; the run had started twenty-two minutes before the commit existed. Compare the run's start time to the commit's, then re-derive nothing else.
- Do not read an unknown or empty result as zero, and do not confirm delivery by the fact that you pushed.
- Do not re-litigate a decision already made, or re-audit your own prior turns after correcting one in a line.
- Do not let the sweep keep asking about the previous round's checks — that reports "nominal" while the board sits on nothing.
