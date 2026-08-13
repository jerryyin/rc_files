---
name: overnight-harvest
description: >-
  Turn the output of an unattended run — an overnight agent round, a long
  autonomous investigation, a batch of experiments — into a repository a
  stranger can navigate. Three jobs: place each artifact where a reader will
  look for it, compact duplicates and one-shots into reusable form, and flag
  the artifacts that should not exist at all. Use the morning after a long run,
  on "clean up last night", "compact the results", "review yesterday's rounds",
  or whenever a repo has accreted rescue folders, near-duplicate scripts, and
  documents only their author can read.
---

# Overnight Harvest

An unattended run optimizes for not losing anything. It writes under time
pressure and stops on a hard boundary. So the failure is never that work is
missing — it is that the work is unfindable, unreadable, and duplicated.
Harvesting is the separate pass that makes it usable.

**Compaction must not change a recorded number, status, scope limit, or the
identity of the environment a number came from.** Prose may be rewritten
freely; results may only be moved and re-linked. If a rewrite would alter what
the project believes, it is not compaction.

Lean on `investigate-dont-assert` for every claim about what an artifact is or
who reads it, and on `state-sync` when the run also left loose files outside
the repo.

## Phase 0 — Reconstruct the round before touching anything

You cannot file what you do not understand, and the run's own summary is the
least reliable account of it.

- Read the authorization and the close for the round, then the commit list,
  then the artifacts. In that order.
- Write one paragraph: what was asked, what actually ran, what was concluded,
  what was left blocked.
- List what the round *claims*. Each claim gets checked against an artifact in
  Phase 6.

Reconnaissance is read-only. Do not move anything yet.

## Phase 1 — Reconcile every copy first

A long run usually spans more than one checkout: a container, a host, a remote.
Moving files while the copies disagree turns a merge into a clobber.

- Enumerate the copies and diff them: commits in one and not another,
  uncommitted work, and any file present twice with different content.
- Resolve divergence explicitly and record which copy won and why. An unpushed
  commit in a container that is about to be discarded is the classic silent
  loss.
- Placement begins only once the copies agree.

## Phase 2 — Classify by the reader, not the producer

Sort every artifact into exactly one of:

- **Result** — a measurement or outcome someone will cite. Scarcest, and most
  often misfiled.
- **Instrument** — how to produce or validate a result: harness, fixture, gate,
  boundary definition.
- **Narrative** — why the round went as it did: rulings, decisions, round
  state, incident notes.
- **Scrap** — scaffolding that existed only to get through the night.

Folders should be named for what a reader wants when opening them. If the
folders are named for what produced the files, that is the first defect to fix.

## Phase 3 — Place, and treat misfiling as the main failure

Deletion is rare. **Misfiling is the dominant way work is lost**, because a
correct result in the wrong folder is never read again. Weight the effort here.

- A passing result must never live in a folder whose name means failure,
  defect, or hazard. Check this explicitly: a run that just climbed out of a
  fault tends to file everything under the fault.
- Move with the repo's rename tracking, and fix every inbound reference and
  index count in the same commit. A move that leaves a dangling link is worse
  than no move.
- **The rescue dump is an anti-pattern, not a placement.** A folder holding a
  tarball, a diff, and an inventory file is a deferral: it converts "I do not
  know where this belongs" into permanent debt nobody will open. Unpack it,
  place each item by its class, delete the wrapper. An item that cannot be
  placed is scrap — say so and drop it.
- Never leave caches, build output, or binaries committed as part of a rescue.

## Phase 4 — Compact

- **Duplicates collapse.** The same content in two places gets one home; the
  other becomes a reference.
- **One-shots become tools.** N near-identical single-experiment scripts are
  one parameterized tool plus N recorded invocations. Promote when the family
  has stopped changing, and keep the invocations so past runs stay
  reproducible.
- **Prose that exists to justify one sentence should be that sentence.** A
  document whose whole content is "we checked X and it changed nothing" belongs
  inline where X is described, with a pointer to the raw artifact. Demote the
  prose; never delete the evidence.
- **Knowledge that must be re-implemented is a missing script.** If a folder
  holds procedures as prose, either the executable form exists beside it or the
  prose states why it cannot be automated. Prose silently standing in for a
  tool gets re-derived, differently, every time.

## Phase 5 — Make it readable by someone who was not there

The most-skipped step, and the reason old rounds become unusable.

- **Every document opens with its own context.** First paragraph: what question
  it answers, on what system, and what the reader must know to parse the rest.
  Jargon only after that.
- **Internal codenames are not an interface.** Any label the run invented —
  experiment IDs, phase names, arm letters — is expanded at first use in every
  document that uses it. Readers arrive by search, not by reading the project
  in order.
- Say what a result *means* before how it was obtained.

The test: hand the document to someone who joined today. If they must open
another file to parse the first paragraph, rewrite it.

## Phase 6 — Detect the problematic

Flag these; do not quietly fix them.

- A claim with no artifact behind it, or an artifact no index references.
- The same quantity stated in two places with different values.
- Numbers from a withdrawn, voided, or superseded line of work still written as
  quotable.
- A result whose recorded environment does not match where it actually ran.
- Anything named inventory, rescue, temp, misc, or dated scratch.
- Confident prose whose underlying run failed, was blocked, or never launched.

These change what the project believes. Report with evidence and let the owner
rule.

## Working shape

Reconnaissance and classification are cheap and parallelizable; placement is
consequential and serial.

- Dispatch parallel read-only agents by domain. Give each explicit acceptance
  criteria and require a placement plan with evidence and open questions —
  plans only, no writes.
- Adjudicate the plans yourself and resolve conflicts between them; agents
  working in separate domains will propose contradictory homes for the same
  file.
- Execute the moves in one coherent pass. Present deletions and bulk moves for
  approval first.

## Checklist
- [ ] Round reconstructed from authorization, commits, and artifacts before any edit.
- [ ] All copies reconciled; divergence resolved explicitly.
- [ ] Every artifact classified result / instrument / narrative / scrap.
- [ ] No passing result filed under a failure-meaning folder.
- [ ] Rescue and inventory wrappers unpacked and removed, not re-filed.
- [ ] Duplicates collapsed; repeated one-shots promoted or scheduled for promotion.
- [ ] Inbound references and index counts updated in the same commit as each move.
- [ ] Every retained document opens with context a newcomer can parse.
- [ ] Problematic artifacts reported with evidence, not silently fixed.
- [ ] No recorded number, status, scope limit, or environment identity changed.
