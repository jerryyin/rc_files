# Code Review Workflow

Applies when: Preparing or processing staged code review, inline RVW/RVWY feedback, or an explicitly authorized commit stack.

## Commit Stack Workflow

Prepare changes for staged review. Create WIP commits, squash, amend, or publish a stack only when that Git action is authorized in the current user turn under the shared AGENTS.md. An instruction to process review feedback authorizes the described edits, not an automatic commit.

### Two Review Modes

| Mode | When | Diff |
|------|------|------|
| **Incremental** | After each AI batch | Staged and unstaged changes; use commit ranges only for an authorized committed batch |
| **Milestone** | Before PR/squash | Merge-base diff against the actual target branch, plus staged and unstaged changes |

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
git log <target-branch>..HEAD --oneline
git diff <target-branch>...HEAD --stat
git diff --cached --stat
git diff --stat
```

Suggest a PR commit message:
```
<Short summary>

<Description of what changed and why>

Changes:
- Bullet points
```

