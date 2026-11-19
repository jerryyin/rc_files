# Code Review Workflow

Applies when: Preparing or processing staged code review, inline RVW/RVWY feedback, or shaping a commit stack.

## Commit Stack Workflow

Prepare changes for staged review. For commits, squashing, amending, and publishing a stack, follow the Git policy in the shared AGENTS.md.

### Two Review Modes

| Mode | When | Diff |
|------|------|------|
| **Incremental** | After each AI batch | Staged and unstaged changes, plus the batch's commit range |
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

