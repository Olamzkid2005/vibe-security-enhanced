---
inclusion: fileMatch
fileMatchPattern: "**/*.{ts,tsx,js,jsx,py,go,swift,kt}"
---

# Code Reviewer

When reviewing code in this project, apply the following standards consistently. This document governs how to assess pull requests, evaluate code quality, and produce review verdicts.

---

## Review Verdict Thresholds

| Score | Verdict |
|-------|---------|
| 90+ with no high-severity issues | Approve |
| 75–89 with ≤2 high-severity issues | Approve with suggestions |
| 50–74 | Request changes |
| <50 or any critical issue | Block |

Complexity score (1–10) and risk level (critical / high / medium / low) must be determined before issuing a verdict.

---

## Automatic Blockers (Critical Issues)

Flag any of the following as **critical** — they block approval regardless of score:

- Hardcoded secrets, passwords, API keys, or tokens
- SQL injection via string concatenation
- Missing auth/authz checks on protected operations
- Unhandled promise rejections that can silently swallow errors
- Data races or unsafe concurrent access

---

## Code Quality Thresholds

Flag violations at these thresholds:

| Issue | Threshold |
|-------|-----------|
| Function length | > 50 lines |
| File length | > 500 lines |
| Methods per class | > 20 |
| Nesting depth | > 4 levels |
| Function parameters | > 5 |
| Cyclomatic complexity | > 10 branches |

Also flag: missing error handling, unused imports, magic numbers, debug statements (`console.log`, `debugger`), disabled lint rules, and `TODO`/`FIXME` comments left in production paths.

---

## SOLID & Design Smell Checks

- **Single Responsibility**: classes and modules should have one reason to change
- **Open/Closed**: prefer extension over modification
- **Dependency Inversion**: depend on abstractions, not concretions
- **God classes**: split by responsibility
- **Long methods**: extract into smaller, named functions
- **Deep nesting**: use early returns and guard clauses
- **Boolean blindness**: replace with named parameters or enums
- **Stringly typed**: use proper types or enums
- **N+1 queries**: eager load or batch; never query inside a loop

---

## Language-Specific Rules

| Language | Key Rules |
|----------|-----------|
| TypeScript | Explicit type annotations; no `any`; null safety enforced; async/await over raw promises |
| JavaScript | `const`/`let` only (no `var`); ES modules; no floating promises |
| Python | Type hints on public APIs; catch specific exceptions (not bare `except`); follow class design conventions |
| Go | All errors handled (no `_` on error returns); goroutine safety verified; struct design over inheritance |
| Swift | All optionals explicitly handled; prefer protocols over class inheritance |
| Kotlin | Null safety enforced; prefer data classes; coroutines used correctly |

---

## Review Checklist

**Pre-review:**
- [ ] Build passes
- [ ] Full test suite passes
- [ ] PR description explains what changed and why

**Correctness:**
- [ ] Logic is correct for the stated intent
- [ ] Edge cases and boundary conditions handled
- [ ] Error handling present and meaningful
- [ ] No concurrency or race condition issues

**Security:**
- [ ] All inputs validated and sanitized
- [ ] No injection vulnerabilities
- [ ] No hardcoded secrets
- [ ] Auth/authz checks present where required

**Performance:**
- [ ] No N+1 query patterns
- [ ] No unbounded collection growth
- [ ] Caching applied where appropriate

**Maintainability:**
- [ ] Names are clear and intention-revealing
- [ ] No god classes or excessively long methods
- [ ] No unnecessary duplication (DRY)
- [ ] Comments explain *why*, not *what*

**Testing:**
- [ ] All new code has corresponding tests
- [ ] Tests cover both happy path and error/edge cases
- [ ] Tests assert behavior, not implementation details

---

## Review Output Format

When producing a review, structure output as:

1. **Verdict** — one of: Approve / Approve with suggestions / Request changes / Block
2. **Score** — 1–100
3. **Risk level** — critical / high / medium / low
4. **Critical issues** — list any blockers first
5. **High/medium issues** — grouped by file, with line references where possible
6. **Suggestions** — optional improvements (non-blocking)
7. **File review order** — prioritized list if multiple files changed
