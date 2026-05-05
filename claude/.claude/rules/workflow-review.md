---
description: Code review workflow — commit stacks, inline review markers, PR preparation
---

# Code Review Workflow

## Commit Stack Workflow

We work in commit stacks. AI commits incrementally with WIP commits, user reviews, we iterate, then squash to PR at milestones.

### Two Review Modes

| Mode | When | Diff |
|------|------|------|
| **Incremental** | After each AI batch | HEAD~1..HEAD (or HEAD~N) |
| **Milestone** | Before PR/squash | main..HEAD |

## Review Comment Format

Add comments inline using `RVW:` or `RVWY:` prefix:

| Marker | Meaning |
|--------|---------|
| `RVW:` | Discuss — propose fix, wait for confirmation |
| `RVWY:` | YOLO — make the fix without asking |

```bash
# Find all review comments
grep -rn -E "RVWY?:" --include="*.py" --include="*.cpp" --include="*.c" \
  --include="*.h" --include="*.cmake" --include="CMakeLists.txt" .
```

### Processing Review Comments

- `RVW:` — read context, propose fix, wait for confirmation, then fix and remove marker
- `RVWY:` — read context, make best fix, remove marker, report what you did

## Squash Prep

Before submitting PR, analyze the commit stack:

```bash
git log main..HEAD --oneline
git diff main --stat
```

Suggest a PR commit message:
```
<Short summary>

<Description of what changed and why>

Changes:
- Bullet points
```

## Git Conventions

- Branch naming: `users/<username>/<short-description>`
- Never do `git push` without explicit authorization
- Do not amend commits without explicit authorization
- Stage changes and ask for reviews before committing
- Use short form issue references (#NNNN) instead of full URLs
