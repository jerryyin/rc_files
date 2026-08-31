---
description: Supervising a long unattended campaign on a shared machine — loop wakes, routine status checks, board recovery, and what the parent agent keeps for itself versus delegates to a subagent
---

# Unattended Campaign Supervision

Applies when a campaign runs for hours or days without the operator present, and a loop or timer wakes this agent to check on it.

## Delegate the routine sweep

On every wake, launch a subagent to perform the status check and any board recovery. Do not perform the sweep inline. The parent's context is a scarce resource reserved for direction: writing rulings, designing gates, deciding what gets measured next, and noticing that a result changes the plan.

Give the subagent the machine access path, the container name, the state files, the standing orders, and the current ruling, because it starts with none of the conversation.

## A ruling is delivered when it is acknowledged, not when it is pushed

Committing and pushing an instruction proves only that the operator wrote it. Before treating a decision as delivered, confirm the agent can see it and has taken it: the checkout it actually reads contains the commit, and it has written a receipt. On 2026-08-16 two rulings were committed, pushed, and written to a plausible-looking file, and the board still sat idle — the agent read a different clone, and nothing had rung its doorbell.

Use the campaign's own delivery tool rather than hand-rolling the steps. Long-running campaigns grow one precisely because this failure recurs, and it already encodes the parts that are easy to skip: hash-verifying the message landed, waking an agent that has ended its turn, and listing messages with no receipt. Hand-delivery reproduces the bug the tool was written to fix.

Check for an unacknowledged message on every wake. An agent that has finished a turn is not polling; it is idle until something wakes it, and from the operator's side that looks identical to an agent that is working.

## Keep the decisions, delegate the observations

The subagent observes and may remediate within already-written policy. It never decides campaign questions: it does not select a cell, admit a variant, change a gate, reinterpret a ruling, or invent authorization. Anything not already answered in writing escalates to the parent.

Spot-check its report against the authorized direction rather than re-deriving its observations. The question to ask is "is the board working on the rung it should be on," not "let me verify each number myself." Re-deriving the sweep defeats the delegation.

## Escalate immediately, not on the next wake

The subagent reports at once when work has stopped or is about to, when a stopping condition fires, when the board is unusable, or when the campaign has reached a decision the written rulings do not cover. A campaign that idles overnight waiting for a wake has lost the hours that made it unattended work in the first place.

## Write gates that stop the claim, not the work

Before leaving a campaign unsupervised, re-read the stopping conditions with the operator absent. A gate written for a supervised round becomes an idle board when nobody is there to answer it. Stop the comparison, record the refusal, drop to the next authorized item — and reserve true halts for when the machine itself is at risk.
