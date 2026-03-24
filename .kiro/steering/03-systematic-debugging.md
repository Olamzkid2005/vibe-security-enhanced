---
inclusion: always
---

# Systematic Debugging

Apply this skill for any bug, test failure, or unexpected behavior — before proposing any fix.

## Iron Law

```
NO FIXES WITHOUT COMPLETING PHASE 1 FIRST
```

Symptom fixes are failure. Always find the root cause.

## The Four Phases

Complete each phase before moving to the next.

### Phase 1: Root Cause Investigation

1. **Read error messages fully** — stack traces, line numbers, file paths, error codes. They often contain the answer.
2. **Reproduce consistently** — establish exact steps. If not reliably reproducible, gather more data; do not guess.
3. **Check recent changes** — `git diff`, recent commits, new dependencies, config or environment changes.
4. **Trace data flow** — follow the bad value back to its origin. Fix at the source, not at the symptom.
5. **Multi-component systems** — log inputs and outputs at each component boundary. Run once to gather evidence, then analyze to identify the failing component.

Phase 1 is complete when you can state: *"The root cause is X because Y."*

### Phase 2: Pattern Analysis

1. **Find working examples** — locate similar working code in the same codebase.
2. **Read references completely** — if applying a known pattern, read the reference implementation in full. Do not skim.
3. **List every difference** — between working and broken code. Do not dismiss small differences.
4. **Understand dependencies** — config, environment, assumptions the code makes.

### Phase 3: Hypothesis and Testing

1. **Form one hypothesis** — state it explicitly: *"I think X is the root cause because Y."*
2. **Test minimally** — make the smallest possible change to test the hypothesis. One variable at a time.
3. **Evaluate result** — hypothesis confirmed → Phase 4. Not confirmed → form a new hypothesis. Do not stack fixes.
4. **When uncertain** — say so. Do not pretend to know. Ask or research.

### Phase 4: Implementation

1. **Write a failing test first** — simplest possible reproduction. Use the TDD skill. This is mandatory.
2. **Implement one fix** — address the root cause only. No "while I'm here" changes, no bundled refactoring.
3. **Verify the fix** — test passes, no regressions, issue resolved.
4. **If the fix doesn't work** — stop. Count attempts:
   - Fewer than 3: return to Phase 1 with new information.
   - 3 or more: **stop and question the architecture** before attempting anything else.

**Architectural problem signals (3+ failed fixes):**
- Each fix exposes a new problem in a different place
- Fixes require large-scale refactoring to implement
- Each fix creates new symptoms elsewhere

When these appear, discuss with the user before proceeding.

## Red Flags — Stop and Return to Phase 1

Any of these thoughts means you are skipping the process:

- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "It's probably X, let me fix that"
- "I don't fully understand but this might work"
- "Here are the problems:" *(listing fixes before investigation)*
- "One more fix attempt" *(after 2+ already tried)*
- Each fix reveals a new problem in a different place

**All of these → STOP. Return to Phase 1.**

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Issue is simple, skip the process" | Simple bugs have root causes too. The process is fast for simple bugs. |
| "Emergency, no time" | Systematic is faster than guess-and-check thrashing. |
| "Just try this first" | First fix sets the pattern. Do it right from the start. |
| "I'll write the test after" | Untested fixes don't stick. Test first. |
| "Multiple fixes at once saves time" | You can't isolate what worked. It causes new bugs. |
| "Reference is too long, I'll adapt" | Partial understanding guarantees bugs. Read it fully. |
| "I see the problem, let me fix it" | Seeing symptoms ≠ knowing root cause. |
| "One more attempt" (after 2+ failures) | 3+ failures = architectural problem. Stop and question. |

## Quick Reference

| Phase | Activities | Done When |
|-------|-----------|-----------|
| 1. Root Cause | Read errors, reproduce, check changes, trace data flow | You can state what broke and why |
| 2. Pattern | Find working examples, compare differences | Differences identified |
| 3. Hypothesis | State theory, test minimally | Hypothesis confirmed or replaced |
| 4. Implementation | Write failing test, fix, verify | Tests pass, no regressions |
