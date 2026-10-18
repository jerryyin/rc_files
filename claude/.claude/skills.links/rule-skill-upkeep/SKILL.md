---
name: rule-skill-upkeep
description: >-
  Curate the rules and skills themselves: capture a reusable lesson, amend or
  audit existing guidance, or evaluate and fuse an external skill collection.
  Use on requests to add/update a rule or skill, remember a correction, check
  whether guidance is stale, consolidate duplicates, or import useful skills.
  Chooses the right home, sharpens retrieval triggers, removes overlap, verifies
  environment claims, and preserves only behavior-changing instructions.
---

# Rule / Skill Upkeep

Rules and skills are executable context. Optimize for reliable retrieval, correct behavior, and low maintenance cost—not completeness.

Apply `investigate-dont-assert` when auditing claims. Obey the current turn's Git and mutation authority. Before a Git write, summarize the intended action and affected files; editing never implies permission to commit or push.

## Choose the home

- **Rule:** ambient behavior that must apply automatically whenever its matching context appears.
- **Skill:** an on-demand, multi-step workflow or specialized reference that earns the cost of separate discovery.
- **Existing file:** the default home. Widen its description or add the missing branch instead of creating a near-duplicate.
- **Reference:** detailed, branch-specific material that a skill needs only sometimes. Link it directly from `SKILL.md` with the condition for reading it.

Create a new skill only when it has a distinct trigger and procedure that cannot fit cleanly in an existing home.

## Author or amend

1. Extract the generalizable lesson. Exclude the one-off incident unless it is the smallest useful example.
2. Find the closest source of truth and read its surrounding guidance before editing.
3. Write the retrieval pointer first. A description must say what the material does and encode one trigger for each genuinely different branch; collapse synonyms that describe the same branch.
4. Write imperative steps in execution order. End each step with a checkable completion condition when “done” could otherwise be ambiguous.
5. Keep one source of truth per meaning. Phrase the positive target behavior; reserve prohibitions for real guardrails.
6. Treat code, configuration, layout, and `--help` output as authoritative. Document only conventions, reasoning, and costly-to-rediscover gotchas rather than caching easy lookups.
7. Match the collection's schema, voice, density, naming, and product conventions. When creating a new skill, use the supported initializer and metadata generator rather than copying another harness's frontmatter.
8. Validate the changed skill and forward-test complex behavior when safe and useful.

## Fuse an external collection

Inventory both collections before copying. Classify every upstream skill:

- **Merge:** same trigger or outcome as a local skill. Preserve only mechanisms that change behavior and integrate them into the local workflow.
- **Add:** distinct, recurring need with a clear local use case. Adapt terminology, safety gates, tools, and completion criteria to the local environment.
- **Omit:** thin wrapper, experimental material, ecosystem-specific setup, low-frequency preference, weaker duplicate, or behavior that conflicts with local policy.

Judge ideas independently of upstream packaging. A useful clause does not justify importing its entire workflow. Remove automatic commits, external writes, broad builds, destructive operations, or mandatory user questioning unless current local policy and task authority support them.

Keep adapted files concise: delete duplicated explanations, anecdotes, and generic advice the model already follows. Preserve attribution or license notices when copied material requires them.

## Audit

Bound the audit to the files and claims relevant to the request. For each environment-dependent claim, verify it against the live path, command, flag, version, or tool behavior and classify it as accurate, stale, wrong, or unverified. Fix objective drift; surface judgment calls separately.

Audit retrieval and structure too:

- Does the description fire on every intended branch without synonym padding?
- Is branch-specific detail progressively disclosed instead of obscuring the core workflow?
- Does every line change behavior relative to the model's default?
- Are duplicated meanings, stale caches, and obsolete product mechanics removed?

## Finish

Run targeted validation, inspect the final diff, and confirm the live configuration resolves to the edited source. Summarize what was merged, added, omitted, and why. If the repository workflow calls for staging before review, state the exact files and stage only the task changes. Commit or push only when explicitly authorized in the current user turn.

## Completion check

- [ ] Every change has one clear home and retrieval trigger.
- [ ] External duplicates were merged rather than installed in parallel.
- [ ] New skills cover distinct, recurring workflows.
- [ ] Environment-specific claims were verified or labeled unverified.
- [ ] Changed skills validate and contain no template residue.
- [ ] Git and external actions stayed within current-turn authority.
