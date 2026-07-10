---
name: rule-skill-upkeep
description: >-
  Curate the Claude rules and skills themselves. Two modes: (1) author/amend —
  turn a lesson, correction, or preference from the user into a rule or skill,
  choosing the right home and making its description a good recall trigger;
  (2) audit — scan existing rules/skills and verify each claim against the live
  session, flagging stale, wrong, or unverified content. Use on "add/update a
  rule or skill", "capture this as a rule", "remember this in a rule", "are the
  rules still accurate", or "audit/scan the rules". Commit to the tracked
  dotfiles repo when done.
---

# Rule/Skill Upkeep

Rules and skills are code too: they should be terse, correct, and land where the
model will actually find them. This skill maintains them. It leans on
`investigate-dont-assert` for evidence and `state-sync` for committing tracked
state.

## Dispatch

- **Author/amend** — the user gives a lesson, correction, or preference to
  capture. Go to *Authoring*.
- **Audit** — the user asks whether the rules/skills are still accurate, or you
  finish a session that surfaced drift. Go to *Auditing*.

Often do both: capture the new lesson, then check nearby content for staleness.

## Rule vs skill, and where it goes

- **Rule** = ambient guidance loaded every session. Use it for behavior you want
  to happen *by default*, without being asked.
- **Skill** = a procedure invoked on demand. Use it for a heavyweight, multi-step
  workflow triggered deliberately.
- If the goal is "do X automatically when situation Y arises," it is a rule, not
  a skill — a skill that must be invoked defeats "by default."
- Prefer **amending the closest existing file/section** over creating a new one.
  Create a new file only when the topic has no home.

## Authoring (add/amend from input)

- **Capture the generalizable lesson, not the instance.** Strip the specific
  problem; keep the transferable principle. Gear it to the domain, not the one
  bug. (What was non-obvious here that will recur?)
- **Put it in the right home** — the file whose topic it matches, the closest
  existing section first.
- **Match the file's voice** — terse imperative bullets, same density and
  formatting as its neighbors. No narration of the obvious.
- **The `description` is the retrieval key.** Write it so the rule/skill is
  recalled in exactly the situations it should fire. If an existing rule should
  now cover a new situation, *widen its description* rather than adding a
  near-duplicate.
- **Earn each line.** Reject one-off or project-narrow facts (they belong in
  notes, not a general rule). Don't duplicate existing coverage. If unsure a fact
  is broad enough, ask before adding it.

## Auditing (scan for accuracy)

Apply `investigate-dont-assert` for the evidence discipline — verify each claim
by running the check (not from memory or the rule's own wording), and on
challenge re-check rather than defend. What is specific to auditing docs:

- **Rules go stale.** A claim that was true can quietly become false — a path
  moved, a flag renamed, a default changed. Verify the wording against today's
  environment, not against when it was written (paths, env vars, build flags,
  file lists, script existence).
- **Classify each claim:** accurate / stale / wrong / unverified; say plainly
  what you did not check.
- **Report tight, then fix.** What still holds, what drifted, a concrete diff per
  fix. Apply objective corrections; get sign-off on judgment calls.

## Finish

- Rules/skills live in a tracked dotfiles repo. After edits, commit and push per
  the git action gate: state the intended action and affected files first, then
  commit to the repo's branch/convention.
- Confirm the active config path. If the live location is a copy rather than a
  symlink of the source you edited, mirror it so the change takes effect.
