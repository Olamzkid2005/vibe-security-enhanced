# Superpowers Skills - Quick Reference

## When to Use Each Skill

| Situation | Use This Skill | Key Action |
|-----------|---------------|------------|
| Starting new feature | 01-brainstorming | Design first, get approval |
| Implementing code | 02-test-driven-development | Write test, watch fail, implement |
| Fixing bugs | 03-systematic-debugging | Find root cause (4 phases) |
| About to claim "done" | 04-verification-before-completion | Run verification, show evidence |
| Planning multi-step work | 05-writing-plans | Break into 2-5 min tasks |
| Before merging/committing | 06-requesting-code-review | Self-review checklist |

## The Iron Laws

### Brainstorming
```
NO CODE WITHOUT DESIGN APPROVAL FIRST
```

### TDD
```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

### Debugging
```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

### Verification
```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

## Red Flags

If you think:
- "This is too simple to need a design" → Use brainstorming
- "I'll write tests after" → Use TDD
- "Quick fix for now" → Use systematic debugging
- "Should work now" → Use verification
- "Just start coding" → Use writing plans
- "Skip review, it's simple" → Use code review

## Quick Workflows

### New Feature
1. Brainstorming → Design + approval
2. Writing Plans → Break into tasks
3. TDD → Implement (test-first)
4. Verification → Prove completion
5. Code Review → Quality check

### Bug Fix
1. Systematic Debugging → Root cause (4 phases)
2. TDD → Failing test + fix
3. Verification → Prove fixed
4. Code Review → Review fix

### Ad-Hoc Task
1. Brainstorming → Quick design
2. TDD → Test-first
3. Verification → Evidence
4. Code Review → Quality gate

## Philosophy

- **Test-Driven Development** - Write tests first, always
- **Systematic over ad-hoc** - Process over guessing
- **Complexity reduction** - Simplicity as primary goal
- **Evidence over claims** - Verify before declaring success
