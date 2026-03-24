---
inclusion: always
---

# Requesting Code Review

Apply when completing a major feature, fixing a complex bug, or before merging to main.

## When Review is Mandatory

- After completing a major feature
- Before merging to main
- After fixing a complex bug

## When Review is Optional (but valuable)

- When stuck — a fresh perspective helps
- Before refactoring — establish a baseline
- After completing multiple related tasks

## Pre-Review Checklist

Complete this before requesting review. Do not skip items.

- [ ] All tests pass (run the full suite, read the output)
- [ ] No console errors or warnings
- [ ] Code follows existing project conventions and patterns
- [ ] No commented-out code
- [ ] No debug statements or temporary logging
- [ ] Error handling is in place
- [ ] Edge cases are covered
- [ ] Documentation updated where behavior changed

## How to Present the Review

Provide the following context when requesting review:

1. What changed — summarize the diff (`git diff HEAD~1` or `git diff origin/main`)
2. What it should do — reference the spec, plan, or requirements
3. Test results — paste or summarize the test runner output
4. Any concerns — flag anything uncertain or worth extra scrutiny

## Acting on Feedback

| Severity | Action |
|----------|--------|
| Critical | Fix immediately before proceeding |
| Important | Fix before merge |
| Minor | Note for later; do not block on it |

If you believe feedback is incorrect, push back with technical reasoning and evidence (code, test output). Do not silently ignore it.

## Hard Rules

- Never skip review because something "seems simple"
- Never ignore Critical or Important issues
- Never argue with valid technical feedback — fix it
- Never proceed to merge with unresolved Critical issues
