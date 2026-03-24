---
inclusion: always
---

# Verification Before Completion

Apply before claiming work is complete, fixed, or passing — and before any commit, PR, or task sign-off.

## Iron Law

```
NO COMPLETION CLAIM WITHOUT FRESH VERIFICATION EVIDENCE
```

If you have not run the verification command in this response, you cannot claim it passes.

## The Gate

Before any claim of success or completion:

1. **Identify** — what command proves this claim?
2. **Run** — execute it fresh and in full
3. **Read** — check full output, exit code, and failure count
4. **Verify** — does the output confirm the claim?
   - No → state actual status with evidence
   - Yes → state the claim with evidence attached
5. **Then claim** — not before

Skipping any step is asserting something you have not verified.

## What Each Claim Requires

| Claim | Required evidence | Not sufficient |
|-------|------------------|----------------|
| Tests pass | Test runner output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors/warnings | Partial check, extrapolation |
| Build succeeds | Build command exits 0 | Linter passing, logs look fine |
| Bug fixed | Original symptom test passes | Code changed, assumed fixed |
| Regression test works | Red → Green cycle observed | Test passes once after writing |

## Red Flags — Stop Immediately

Any of these means verification has been skipped:

- Using "should", "probably", "seems to", "looks like"
- Expressing satisfaction before running verification ("Done!", "Perfect!", "Looks good!")
- Relying on a previous run from an earlier message
- Trusting a tool or agent success report without independent confirmation
- Partial verification ("linter passed" does not mean build passes)
- "Just this once" reasoning

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Should work now" | Run the command |
| "I'm confident" | Confidence is not evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent reported success" | Verify independently |
| "Partial check is enough" | Partial proves nothing |

## Correct Patterns

**Tests:**
```
✅ Run test suite → see "34/34 passed" → claim "all tests pass"
❌ "Should pass now" / "Looks correct"
```

**Regression (TDD red-green):**
```
✅ Write test → run (fails) → implement fix → run (passes) → verified
❌ "I've written a regression test" without observing the red-green cycle
```

**Build:**
```
✅ Run build command → exit 0 → claim "build passes"
❌ "Linter passed" (linter does not check compilation)
```

## Scope

This rule applies to every form of completion signal:

- Explicit claims ("done", "fixed", "passing", "complete")
- Expressions of satisfaction ("great", "perfect", "looks good")
- Implications of success ("that should do it", "this covers it")
- Task sign-offs, commits, PRs, and moving to the next task

Run the command. Read the output. Then make the claim.
