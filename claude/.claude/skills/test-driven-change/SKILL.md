---
name: test-driven-change
description: >-
  Implement a feature or bug fix as small red-green slices, with tests that
  observe behavior through the narrowest faithful seam and expected results from
  an independent oracle. Use when the user requests TDD, red-green-refactor,
  test-first work, a regression test before a fix, or incremental implementation
  driven by executable behavior.
---

# Test-Driven Change

Build one observable behavior at a time: prove the test can fail for the intended reason, write only enough implementation to pass it, then repeat.

## Establish the seam and oracle

1. Pin the task contract and the next behavior in one sentence.
2. Choose the cheapest seam that faithfully exposes that behavior. Valid compiler and systems seams include a public API, pass boundary, input/output IR contract, diagnostic, runtime result, emitted assembly, or differential reference result.
3. Ask the user about the seam only when the choice would materially change the public design, cost, or scope.
4. Choose an independent oracle: a specification, known literal, worked derivation, reference implementation/backend, or previously verified artifact. Never compute the expected value with the same logic under test.

## Run one vertical slice

1. Write one focused test for one behavior.
2. Run the narrowest relevant command and observe the expected failure. Confirm it fails because the behavior is absent or wrong, not because the harness is broken.
3. Implement the minimum change that makes this test pass. Do not anticipate later slices.
4. Re-run the same command and observe it pass.
5. Run the nearest affected tests for regressions. Confirm before starting a long build or broad suite.
6. Repeat with the next behavior. Refactor only from green, keeping every prior slice green.

For a reported bug, first turn the verified reproducer into the regression test at the correct seam. If no faithful seam exists, record that architectural gap rather than adding a test that cannot detect the real failure.

## Test quality

- Test observable behavior, not private structure, call counts, or incidental IR unless that IR is the contract being protected.
- Keep the expected result independent of the implementation.
- Mock only genuine external boundaries such as remote services, time, randomness, or hardware unavailable to the test. Prefer real owned code and lightweight local substitutes.
- Make a regression test fail on the original bug and pass on the fix; a nearby failure mode is not enough.
- Use the repository's existing test location, naming, fixtures, and command style.
- Keep each test responsible for one logical behavior, while allowing multiple assertions that jointly establish it.

## Completion check

- [ ] Every kept behavior was observed red before green.
- [ ] Each failure was the intended failure, not a broken harness.
- [ ] Expected values came from an independent oracle.
- [ ] Tests exercise faithful seams and survive irrelevant refactors.
- [ ] Targeted tests pass; broader validation matches the change's risk and user authorization.
