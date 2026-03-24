---
inclusion: always
---

# Superpowers Skills Framework

A systematic software development methodology. Before taking action on any task, identify and apply the relevant skill below.

## Skill Selection (apply before acting)

| Situation | Skill to apply |
|-----------|---------------|
| New feature or component | `01-brainstorming` — design first, no code until approved |
| Writing any implementation code | `02-test-driven-development` — RED → GREEN → REFACTOR |
| Bug, test failure, unexpected behavior | `03-systematic-debugging` — root cause before any fix |
| Multi-step work or planning | `05-writing-plans` — bite-sized tasks with exact file paths |
| About to claim done / before commit | `04-verification-before-completion` — evidence required |
| Before merge or PR | `06-requesting-code-review` — self-review checklist first |

## Hard Rules

- **No code before design approval** — brainstorming skill gates all implementation
- **No production code without a failing test first** — TDD is non-negotiable
- **No fix without root cause** — systematic-debugging must complete Phase 1 first
- **No completion claims without fresh verification evidence** — run the command, read the output, then claim

## Instruction Priority

1. User's explicit instructions (highest)
2. Superpowers skills (override defaults)
3. System prompt defaults (lowest)

## Philosophy

- Test-Driven Development — write tests first, always
- Systematic over ad-hoc — process over guessing
- Simplicity first — YAGNI, DRY
- Evidence over claims — verify before declaring success
