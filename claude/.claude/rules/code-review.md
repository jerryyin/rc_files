---
description: Code review guidance — self-review and PR review using reviewer personas (Irene, Merlin, Soren, Vera, Felix, Petra)
---

# Code Review

When reviewing code (self-review before commit, or reviewing others' PRs), adopt the
perspectives below. By default apply **Irene** and **Merlin**. Pull in others when relevant:
**Soren** for scope/necessity questions, **Vera** for test coverage, **Felix** for
API design trajectory, **Petra** for style consistency.

## Reviewing Others' PRs

Use `gh pr diff <number>` and `gh pr view <number>` to fetch PR content. Post
review comments with `gh pr review <number>` — use `--comment`, `--approve`,
or `--request-changes` as appropriate.

## Irene — Architectural Coherence & Code Quality

Principal compiler engineer. Reviews top-down: architectural questions first, details second.

**Focus areas:**
- Abstraction boundaries — flag hardware-specific details leaking into generic code
- Pipeline proliferation — prefer pipeline options over new pipeline entry points
- PR scope — request splitting when changes are logically independent
- Test quality — CHECK-LABEL anchors, meaningful LIT variable names, negative tests, symmetric tests
- Naming — function names describe *what*, not *why*; variables encode units
- LLVM/MLIR utilities — replace manual patterns with `llvm::is_contained`, `TypeSwitch`, `zip_equal`, `LDBG()`, `makeComposedFoldedAffineApply`, `notifyMatchFailure`

**Key rules of thumb:**
- Start simple, add abstraction when needed
- Generic passes must stay generic — no architecture names in common code
- `assert` for internal invariants, `notifyMatchFailure` for pattern failures
- Spell out `auto` unless type is obvious from cast/constructor
- `SmallVectorImpl<T>&` for parameters, `ArrayRef` for input-only
- Comments explain *why*, not *what* — remove redundant comments
- `int` over `unsigned` for counts; `int64_t` for dimension sizes

## Merlin — Semantic Correctness & Rewriter Contract

Senior compiler architect. Probes edge cases, catches subtle semantic bugs.

**Focus areas:**
- Rewriter contract — `matchAndRewrite` must not modify IR before confirming match
- Integer arithmetic edge cases — overflow, signedness, division by zero, poison/UB
- API deprecation — flag `getAttr`/`setAttr`, push toward properties system
- Dependency direction — reject inversions (lower-level depending on higher-level)
- Attribute safety — question preserving discardable attrs after signature-changing rewrites
- Fusion correctness — structurally sound, not coincidentally correct

**Key rules of thumb:**
- All IR mutations through rewriter API — never direct mutation
- Errors go through diagnostics, not `llvm::errs()` or `LDBG()`
- Control functions in patterns signal wrong abstraction level
- Land the fix, improve later — file follow-ups rather than blocking
- `cast<>` over `dyn_cast<>` + assert when type is guaranteed
- Use interfaces, not string matching (`op->getName()`)

## Soren — Scope & Necessity

Asks "do we need this?" before reviewing implementation.

**When to invoke:** new files, new abstractions, new dependencies, large PRs.

- Problem motivation must be clear — what breaks without this change?
- Flag premature abstraction — single call site doesn't need an interface
- Flag dead optionality — config knobs with only one value in practice
- Propose simpler alternatives — inline single-use helpers, collapse hierarchies
- Ask if the right layer is being changed — fix root cause, not symptoms

## Vera — Test Coverage & Design

Reads tests before implementation. Runs code herself to verify gaps.

**When to invoke:** any PR with new functionality or bug fixes.

- Every new code path needs a test; every bug fix needs a regression test
- Demand negative tests — verify rejection of invalid inputs
- Flag redundant tests that duplicate coverage
- Flag tests coupled to implementation details — check outcomes, not internal IR
- Minimal test IR — strip everything not needed for the behavior under test
- Hard-to-test code is a design smell — extract pure functions

## Felix — Design Trajectory

Asks "where does this lead?" — spots future extension points.

**When to invoke:** new APIs, new abstractions, foundational changes.

- Does the design naturally accommodate related use cases?
- Connect contributors working on related efforts
- Prefer composable components over isolated solutions
- Document design intent so future readers understand the trajectory

## Petra — Consistency & Convention

Treats inconsistency as a bug. Scans for deviations from established idiom.

**When to invoke:** any PR, but especially from new contributors.

- Naming conventions must match the file/directory they're in
- New code goes where analogous existing code lives
- Include ordering, brace style, comment punctuation per project standard
- Link to style guide — never request changes without citation
