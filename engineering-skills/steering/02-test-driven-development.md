---
inclusion: always
---

# Test-Driven Development (TDD)

Apply this workflow when implementing any feature or bugfix. No exceptions.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

If you wrote code before the test: delete it, start over.

## Red-Green-Refactor Cycle

### 1. RED — Write a Failing Test

Write the smallest test that describes the desired behavior.

- One behavior per test
- Descriptive test name
- Use real code; avoid mocks unless I/O or external services make them unavoidable

### 2. Verify RED — Confirm It Fails

Run the test. Confirm:
- It **fails** (not errors out)
- The failure message matches the missing behavior
- It does NOT pass (passing = you're testing existing behavior, fix the test)

If it errors: fix the error and re-run until it fails for the right reason.

### 3. GREEN — Write Minimal Code

Write the simplest code that makes the test pass. No extras, no refactoring, no "while I'm here" changes.

### 4. Verify GREEN — Confirm It Passes

Run the full test suite. Confirm:
- The new test passes
- No previously passing tests are now failing
- No new warnings or errors in output

If other tests break: fix them before moving on.

### 5. REFACTOR — Clean Up

Only after green:
- Remove duplication
- Improve naming
- Extract helpers

Do not add new behavior. Keep tests green throughout.

### 6. Repeat

Write the next failing test for the next behavior.

## Hard Rules

- **Test first, always.** Code written before a test must be deleted.
- **Watch it fail.** A test you never saw fail may not test what you think.
- **One test at a time.** Don't write multiple tests before implementing.
- **Fix code, not tests.** If green breaks, the implementation is wrong.
- **No "I'll add tests later."** Later never comes; tests added after pass immediately and prove nothing.

## Common Rationalizations — All Invalid

| Excuse | Why it's wrong |
|--------|----------------|
| "Too simple to test" | Simple code breaks. The test takes 30 seconds. |
| "I'll test after" | Tests written after pass immediately — they prove nothing. |
| "Already manually tested" | Ad-hoc, unrepeatable, leaves no record. |
| "Deleting hours of work is wasteful" | Sunk cost. Untested code is technical debt. |
| "Keep as reference and adapt" | Adapting existing code = testing after. Delete it. |
| "Need to explore first" | Fine — throw away the exploration, then start with TDD. |
| "Hard to test = bad design" | Correct. Listen to the test; redesign the unit. |

## Red Flags — Stop and Restart

Any of these means: delete the code, start over with TDD.

- Code exists before a test was written
- Test was written after implementation
- Test passed immediately on first run
- You can't explain why the test failed
- You're planning to "add tests later"
- You're rationalizing "just this once"

## Completion Checklist

Before marking any task done:

- [ ] Every new function/method has a corresponding test
- [ ] Each test was observed to fail before implementation
- [ ] Each test failed for the expected reason (missing feature, not a typo)
- [ ] Minimal code was written to pass each test
- [ ] Full test suite passes
- [ ] No new warnings or errors in output
- [ ] Mocks used only where unavoidable (I/O, external services)
- [ ] Edge cases and error paths are covered

Cannot check every box? TDD was skipped. Start over.

## Final Rule

```
Production code exists → a test was written first and observed to fail
Otherwise → it is not TDD
```

No exceptions without explicit user permission.
