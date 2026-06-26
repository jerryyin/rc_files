---
name: state-sync
description: >-
  Reconcile all persistent state before leaving an ephemeral environment (a
  container/pod that gets discarded). Two sweeps — tracked folders (commit & push
  what is worth keeping, flag wrong state for approval) and loose files (place the
  keepers, purge the one-offs). Use at the end of a work session, on "sync my
  state", "what am I missing before I tear down", or "clean up before I exit".
---

# State Sync

When the environment is ephemeral, anything not committed to a tracked repo or
saved to persistent storage is gone at teardown — and anything junk that *is*
committed is permanent noise. This skill reconciles both directions in one pass:
nothing worth keeping is lost, nothing throwaway is kept.

Apply `investigate-dont-assert`: identify what produced each change/file and
whether it is already tracked before deciding its fate. Cite the evidence.

**Produce a categorized plan first, then act.** Commits, pushes, and deletions
are consequential — present the plan and get approval before executing the
destructive or outward-facing parts. Never silently revert, delete, or commit a
state you do not understand.

## Sweep 1 — Tracked folders (commit the keepers, flag the wrong state)

For every tracked repo you may have touched (dotfiles, scripts, vault, project
checkouts), run `git status` and check for unpushed commits. Classify each change:

- **Intentional and worth keeping** → stage in logical splits (one concern per
  commit) and push. Don't bundle unrelated changes.
- **Wrong / anomalous state** → stop and diagnose before touching. A typechange,
  an unexpected symlink, a generated file showing as tracked, or a secret about to
  land in a non-secret file all signal something upstream is mis-wired. Find who
  created it and why, then **present the analysis and ask permission** to fix —
  the right fix is often at the source (the script/config that produced it), not
  the symptom.
- **Noise** (editor swap files, build artifacts) → not for commit; defer to Sweep 2.

Respect ownership boundaries, and treat a crossing as wrong state: secrets belong
to the secret store / runtime sync; non-secret config belongs to the tracked
dotfiles. A non-secret symlinked onto persistent storage, or a secret about to be
committed, is misfiled — fix the owner, not just the file.

## Sweep 2 — Loose files (place or purge)

Enumerate untracked files in your working areas (home, scratch dirs, project
roots). For each, establish what produced it and whether an equivalent is already
tracked, then decide — and decide *every* file:

- **One-off** (debug output, repro artifact, scratch dump, generated metadata) →
  delete.
- **Worth keeping** (a reusable tool, a reference reproducer) → give it a proper
  tracked home. If it is coupled to the task that produced it, refactor it to be
  self-contained and general *first*, then move it under the right repo/subdir for
  its domain. It then becomes a Sweep 1 commit.

Before committing a *new* tool, check what already exists in the domain folder(s)
and the generic tools path (e.g. `~/scripts/tools`). Prefer extending or
parametrizing an existing tool — or merging overlapping ones into modes of a
single tool — over landing a near-duplicate. A new script must be orthogonal to
what's already tracked; if it overlaps, consolidate and update references rather
than adding a parallel copy. Don't naively create new scripts.

Leave nothing undecided: each loose file ends either deleted or tracked in the
right place.

## Leave alone (do not touch)
- Generated/secret files that are intentionally untracked (the live config, the
  vault-injected key, runtime token stores) — they are supposed to be there.
- Active editor swap/lock files — a live session may own them; they clear on exit.
- Persistent host state outside the repos — out of scope unless asked.
- Files the user has explicitly said to keep as-is.

## Anti-patterns
- **Auto-fixing wrong state.** Reverting/committing an anomaly before explaining its cause.
- **Bundled commits.** One commit mixing unrelated concerns instead of logical splits.
- **Committing junk.** Adding debug artifacts or generated/secret files to a repo.
- **Deleting a keeper.** Purging a file that was actually worth refactoring into the scripts repo.
- **Undecided files.** Leaving loose files unclassified so they silently vanish at teardown.
- **Committing without approval.** Pushing or deleting before the user has seen the plan.

## Checklist
- [ ] Every tracked repo: `git status` reviewed and unpushed commits checked.
- [ ] Keepers committed in logical splits and pushed (after approval).
- [ ] Wrong state diagnosed to its source and fixed only with permission.
- [ ] Ownership boundaries intact: secrets vs non-secret config in the right home.
- [ ] Every loose file classified: deleted, or refactored-and-placed.
- [ ] Intentionally-untracked / active / user-pinned files left alone.
- [ ] Plan presented before any push or deletion.
