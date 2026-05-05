---
description: Meta-workspace conventions — directory maps, communication guidelines, design docs
---

# Workspace Context Guidelines

## Meta-Workspace Concept

This is a meta-workspace pattern for AI-assisted development. A separate
meta-repository serves as a "control center" that provides centralized context,
maps directory locations, and contains workflows and helper scripts — without
polluting actual project repositories.

Maintain a `directory-map.md` for all directory locations. Source and build
directories may be scattered across the filesystem; reference by absolute paths.

## Communication Guidelines

### Do
- Provide task-specific instructions for configuration and incremental builds
- Give explicit authorization before pushing or amending commits
- Make decisions when there's genuine disagreement
- Be direct about what you want

### Don't Expect
- Claims that work is "production ready" without justification
- Sycophantic responses — light debate on technical matters is encouraged
- Long build time activities initiated without confirmation

## Design Documentation

When writing design docs, always include an "Alternatives Considered" section:
- List major, rejected options
- Don't include nit-picky differences
- Focus on major architectural alternatives

## Source Navigation

- Source code may be across multiple repositories and worktrees
- Git submodules may be used extensively
- When editing build configs, check both source tree and build tree caches

## Testing

- Run relevant tests after changes
- Use specific test patterns rather than running all tests
