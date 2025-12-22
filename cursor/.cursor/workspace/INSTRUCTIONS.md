# AI-Assisted Development Workspace - Instructions

This workspace is adapted from [stellaraccident/claude-rocm-workspace](https://github.com/stellaraccident/claude-rocm-workspace) - a meta-workspace pattern for AI-assisted development.

## Overview

### What This Is

This is a **meta-workspace** - a separate control center for AI-assisted development that:
- Provides centralized context and documentation for AI assistants
- Maps out where all your project directories live
- Contains workflows, notes, and helper scripts
- Stays version-controlled without polluting your actual project repositories

### Why Use This Pattern?

Rather than cluttering your actual project with AI context files, this separate workspace:
- Keeps AI context organized and versioned
- Allows working across multiple repositories from one place
- Provides persistent task tracking between sessions
- Contains reusable workflows and coding standards

---

## Directory Structure

All files live under `~/.cursor/` (hidden) via stow symlinks from `~/rc_files/cursor/.cursor/`:

```
~/.cursor/
├── rules/                        # Cursor rule files (.mdc) - Cursor auto-loads these
│   ├── python-style.mdc          # Python coding standards
│   ├── workflow-review.mdc       # Review workflow with RVW: comments
│   ├── task-management.mdc       # Task templates and tracking
│   ├── debugging-tips.mdc        # Debugging tips and commands
│   ├── workspace-context.mdc     # General workspace guidelines
│   ├── iree.mdc                  # IREE-specific rules
│   └── ...
└── workspace/                    # AI workspace files
    ├── scripts/
    │   ├── review.py             # Find RVW: comments, show commit stack
    │   ├── sync-status.sh        # Check git status across repos
    │   └── nuke-vscode.sh        # Kill stale VSCode remote server
    ├── tasks/
    │   ├── active/               # Currently active tasks
    │   │   └── example-task.md   # Task template
    │   └── completed/            # Archived completed tasks
    ├── ACTIVE-TASKS.md           # Quick reference of current work
    ├── directory-map.md          # Map of all project directories
    └── INSTRUCTIONS.md           # This file
```

---

## Quick Start

### 1. Update Directory Map

Edit `directory-map.md` to add your actual project paths:

```markdown
| Alias | Path | Notes |
|-------|------|-------|
| iree | /root/iree | IREE compiler project |
| myproject | /path/to/project | My main project |
| build | /path/to/build | Build directory |
```

### 2. Start a New Task

1. Copy `tasks/active/example-task.md` to `tasks/active/my-task.md`
2. Fill in the template
3. Add to `ACTIVE-TASKS.md`
4. Tell AI: "I'm working on my-task"

### 3. Use the Review Workflow

After AI makes changes:
1. Review the diff
2. Add `RVW:` or `RVWY:` comments for feedback
3. Tell AI: "Process review comments"

---

## Cursor Rules System

### How Rules Work

Files in `.cursor/rules/` with `.mdc` extension are automatically loaded. The `globs` field in the frontmatter controls when each rule applies:

```yaml
---
globs: **/*.py       # Applies only to Python files
---
```

If `globs` is empty, the rule applies globally.

### Available Rules

| Rule File | Scope | Purpose |
|-----------|-------|---------|
| `python-style.mdc` | `**/*.py` | Python coding standards (fail-fast, type hints, etc.) |
| `workflow-review.mdc` | Global | RVW: comment review workflow |
| `task-management.mdc` | Global | Task templates and tracking |
| `debugging-tips.mdc` | Global | Build/debug commands |
| `workspace-context.mdc` | Global | General guidelines |
| `iree.mdc` | `**/iree/**` | IREE-specific build/test info |

---

## Review Workflow

### The RVW: Comment System

When reviewing AI-generated code, add inline comments:

| Marker | Meaning |
|--------|---------|
| `RVW:` | **Discuss** - AI proposes fix, waits for your confirmation |
| `RVWY:` | **YOLO** - AI makes the fix without asking |

**Examples:**
```python
# RVW: This logic seems backwards - let's discuss
# RVWY: Add error handling here
```

```cpp
// RVW: Should this handle the null case?
// RVWY: Rename this variable to be clearer
```

### Finding Comments

Use the review script:
```bash
python ~/.cursor/workspace/scripts/review.py comments /path/to/repo
```

Or tell AI: "Find and process review comments"

### Typical Flow

```
AI: [makes changes]
AI: "Ready for review?"

You: [review diff, add RVW: comments to code]

You: "Process review comments"
AI: [for each RVW: shows comment, proposes fix, waits]
AI: [for each RVWY: makes fix immediately]
AI: [commits: "Address review feedback"]

You: "Ready for PR"
AI: [shows full diff since main, suggests squash message]
```

---

## Task Management

### Creating Tasks

1. Copy the template:
   ```bash
   cp ~/.cursor/workspace/tasks/active/example-task.md ~/.cursor/workspace/tasks/active/my-feature.md
   ```

2. Fill in the sections:
   - **Overview**: What and why
   - **Goals**: Checkboxes for objectives
   - **Context**: Background, related work
   - **Investigation Notes**: Date-stamped findings
   - **Decisions**: Rationale and alternatives

3. Add to `ACTIVE-TASKS.md`

### Switching Tasks

Just tell AI: "Let's work on the my-feature task"

AI will read the task file and pick up context.

### Completing Tasks

```bash
mv ~/.cursor/workspace/tasks/active/my-feature.md ~/.cursor/workspace/tasks/completed/
```

Update `ACTIVE-TASKS.md` to remove from active and add to "Recently Completed".

---

## Helper Scripts

### review.py

Find and analyze code:

```bash
# Find RVW: comments
python scripts/review.py comments /path/to/repo

# Show commit stack since main
python scripts/review.py stack /path/to/repo

# Show changed files since last commit
python scripts/review.py changed /path/to/repo
```

### sync-status.sh

Check git status across multiple repos (edit REPOS array first):

```bash
./scripts/sync-status.sh
```

### nuke-vscode.sh

Fix stale VSCode remote connections:

```bash
./scripts/nuke-vscode.sh
```

---

## Python Style Highlights

The `python-style.mdc` rule enforces these key principles:

### 1. Fail-Fast
- Never silently continue on errors
- Raise exceptions immediately for missing/corrupted data

### 2. Use Dataclasses, Not Tuples
- Use `@dataclass` for multi-field return values
- Tuples only for simple pairs like `(x, y)`

### 3. Specific Type Hints
- Never use `Any`
- Extract complex types to `NamedTuple` or `TypeAlias`

### 4. Specific Exception Handling
- Catch specific exceptions, not `Exception`
- Re-raise for bugs/missing tools

### 5. No Timeouts on Basic Tools
- Never add timeouts to readelf, objcopy, etc.

### 6. Validate Output
- Check files exist after creation
- Check files are non-empty

---

## Git Conventions

### Branch Naming
```
users/<username>/<short-description>
```

### Commit Messages
```
<Short summary (50-72 chars)>

<Detailed description>

Changes:
- Bullet point 1
- Bullet point 2
```

### Important Rules
- **Never push without explicit authorization**
- **Never amend without explicit authorization**
- Stage changes and ask for review before committing
- Use short issue refs `#123` not full URLs

---

## Adding Project-Specific Rules

Create a new `.mdc` file in `.cursor/rules/`:

```yaml
---
globs: **/myproject/**
---

# My Project Rules

## Build Commands
...

## Code Style
...
```

---

## Original Source

This workspace is adapted from:
- **Repository**: https://github.com/stellaraccident/claude-rocm-workspace
- **Purpose**: Claude Code workspace for ROCm development
- **Author**: Stella Laurenzo (@stellaraccident)

Key adaptations made:
- Converted Claude Code commands to Cursor-compatible `.mdc` rules
- Simplified VSCode MCP integration (not needed for Cursor)
- Made task/review system standalone without external dependencies
- Generalized from ROCm-specific to project-agnostic

---

## Tips for Effective AI Collaboration

1. **Provide Context**: Use `directory-map.md` and task files
2. **Incremental Changes**: Review after each batch of changes
3. **Use RVW Comments**: Direct feedback in the code itself
4. **Explicit Authorization**: Be clear about what AI can/cannot do
5. **Task Tracking**: Keep `ACTIVE-TASKS.md` current for session continuity

