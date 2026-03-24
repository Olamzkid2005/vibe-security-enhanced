# Superpowers Skills Framework - Export Package

## Overview

A systematic software development methodology for AI coding assistants (Kiro, Claude Code, Cursor, etc.). These steering files provide proven workflows that prevent common mistakes and ensure quality code.

**Version:** 1.0  
**License:** MIT  
**Based on:** [obra/superpowers](https://github.com/obra/superpowers) - An agentic skills framework

## What's Included

This framework provides:

- **6 Core Skills** covering the complete development lifecycle
- **Systematic workflows** for design, implementation, debugging, and verification
- **Test-Driven Development** methodology
- **Evidence-based completion** verification
- **Detailed implementation planning** guidance

## The Skills

### 1. Brainstorming (01-brainstorming.md)
Design and spec creation before implementation.

**Use when:** Starting any new feature or component

**Key principles:**
- Design before code (always)
- Explore 2-3 approaches with trade-offs
- Get user approval before implementation
- Document validated designs

### 2. Test-Driven Development (02-test-driven-development.md)
RED-GREEN-REFACTOR cycle for all code.

**Use when:** Implementing any feature or bugfix

**Key principles:**
- Write test first (watch it fail)
- Write minimal code to pass
- Refactor only after green
- No production code without failing test first

### 3. Systematic Debugging (03-systematic-debugging.md)
4-phase root cause analysis for bugs.

**Use when:** Encountering any bug, test failure, or unexpected behavior

**Key principles:**
- Find root cause before fixing
- No guessing or symptom fixes
- Scientific method (hypothesis → test → verify)
- Question architecture after 3 failed fixes

### 4. Verification Before Completion (04-verification-before-completion.md)
Evidence-based completion verification.

**Use when:** About to claim work is complete, fixed, or passing

**Key principles:**
- No completion claims without fresh verification
- Run the command, read output, then claim
- Evidence before claims (always)
- No shortcuts for verification

### 5. Writing Plans (05-writing-plans.md)
Breaking work into detailed implementation tasks.

**Use when:** Have a spec or requirements for multi-step work

**Key principles:**
- Bite-sized tasks (2-5 minutes each)
- Exact file paths and commands
- Complete code in plan (not "add validation")
- DRY, YAGNI, TDD, frequent commits

### 6. Requesting Code Review (06-requesting-code-review.md)
Pre-review checklist and quality gates.

**Use when:** Completing tasks, before merging, or when stuck

**Key principles:**
- Review early, review often
- Self-review checklist before requesting
- Fix critical issues immediately
- Provide context with review requests

## Philosophy

- **Test-Driven Development** - Write tests first, always
- **Systematic over ad-hoc** - Process over guessing
- **Complexity reduction** - Simplicity as primary goal
- **Evidence over claims** - Verify before declaring success

## Installation

### Quick Install (Recommended)

Run the installer for your platform:

**Windows:**
```cmd
INSTALL.bat
```

**Mac/Linux:**
```bash
chmod +x INSTALL.sh
./INSTALL.sh
```

The installer will guide you through selecting:
1. Which AI assistant (Kiro, Claude Code, Cursor, or all)
2. User-level (all projects) or project-level (one project)

### Manual Installation

#### For Kiro IDE

Copy the steering files to your Kiro directory:

```bash
# User-level (applies to all projects)
cp -r superpowers-skills/steering/* ~/.kiro/steering/

# Project-level (applies to one project)
cp -r superpowers-skills/steering/* /path/to/project/.kiro/steering/
```

#### For Claude Code

```bash
# User-level
cp -r superpowers-skills/steering/* ~/.claude/steering/

# Project-level
cp -r superpowers-skills/steering/* /path/to/project/.claude/steering/
```

#### For Cursor

```bash
# User-level
cp -r superpowers-skills/steering/* ~/.cursor/steering/
```

## Usage

### Automatic Activation

The skills automatically activate based on context:

- **Starting new features?** → Brainstorming skill activates
- **Implementing code?** → TDD skill guides you
- **Fixing bugs?** → Systematic debugging activates
- **About to claim "done"?** → Verification skill checks
- **Planning work?** → Writing plans skill helps
- **Before committing?** → Code review skill activates

### Manual Reference

You can explicitly reference skills:

- "Follow the brainstorming skill for this feature"
- "Use TDD workflow for this implementation"
- "Apply systematic debugging to this issue"
- "Verify this is complete using the verification skill"

### During Development

The skills proactively guide development:

- Prevent code-before-design
- Enforce test-first development
- Stop symptom fixes (require root cause analysis)
- Require evidence before completion claims
- Break complex work into manageable tasks
- Ensure quality before merging

## Quick Reference

| Situation | Use This Skill |
|-----------|---------------|
| Starting new feature | 01-brainstorming |
| Implementing code | 02-test-driven-development |
| Fixing bugs | 03-systematic-debugging |
| About to claim "done" | 04-verification-before-completion |
| Planning multi-step work | 05-writing-plans |
| Before merging/committing | 06-requesting-code-review |

## Red Flags (When Skills Should Activate)

If you catch yourself thinking:

- "This is too simple to need a design" → Use brainstorming
- "I'll write tests after" → Use TDD
- "Quick fix for now" → Use systematic debugging
- "Should work now" → Use verification
- "Just start coding" → Use writing plans
- "Skip review, it's simple" → Use code review

## Example Workflows

### New Feature Development

1. **Brainstorming** - Design the feature, get approval
2. **Writing Plans** - Break into bite-sized tasks
3. **TDD** - Implement each task (test-first)
4. **Verification** - Verify each task completes
5. **Code Review** - Review before merging

### Bug Fixing

1. **Systematic Debugging** - Find root cause (4 phases)
2. **TDD** - Write failing test, fix, verify
3. **Verification** - Prove bug is fixed
4. **Code Review** - Review the fix

### Ad-Hoc Development

1. **Brainstorming** - Quick design (even for "simple" tasks)
2. **TDD** - Test-first implementation
3. **Verification** - Evidence-based completion
4. **Code Review** - Quality check before commit

## Customization

### Project-Specific Additions

Add project-specific steering files to `.kiro/steering/`:

```markdown
---
inclusion: always
---

# Project-Specific Guidelines

[Your custom guidelines here]
```

### Conditional Activation

Make skills activate only for specific files:

```markdown
---
inclusion: fileMatch
fileMatchPattern: '*.py'
---

# Python-Specific Guidelines

[Python-specific rules]
```

### Manual-Only Skills

Create skills that only activate when explicitly referenced:

```markdown
---
inclusion: manual
---

# Advanced Optimization Techniques

[Advanced content]
```

## Benefits

### For AI Assistants

- Clear workflows to follow
- Prevent common mistakes
- Systematic approach to problems
- Quality gates at each step

### For Developers

- Consistent code quality
- Fewer bugs in production
- Better test coverage
- Documented decision-making
- Faster debugging
- Reduced technical debt

### For Teams

- Shared development methodology
- Consistent practices across projects
- Knowledge transfer through documented workflows
- Reduced code review friction

## Common Patterns Prevented

### Anti-Pattern: Code Before Design
**Without Superpowers:** Jump straight to coding, realize design flaws later, rewrite

**With Superpowers:** Brainstorming skill enforces design-first, catches issues early

### Anti-Pattern: Tests After Implementation
**Without Superpowers:** Write code, then tests (tests pass immediately, prove nothing)

**With Superpowers:** TDD skill enforces test-first, ensures tests actually test

### Anti-Pattern: Symptom Fixes
**Without Superpowers:** Try random fixes, create more bugs, waste time

**With Superpowers:** Systematic debugging finds root cause, fix once correctly

### Anti-Pattern: Unverified Completion
**Without Superpowers:** Claim "done" without testing, bugs slip through

**With Superpowers:** Verification skill requires evidence before completion claims

## Best Practices

1. **Trust the process** - Skills exist because these patterns work
2. **Don't skip steps** - Each step prevents specific failure modes
3. **Use for "simple" tasks too** - Simple tasks become complex without process
4. **Customize for your needs** - Add project-specific guidelines
5. **Review regularly** - Update skills based on team learnings

## Troubleshooting

### Skills Not Activating

- Check files are in correct directory (`~/.kiro/steering/` or `.kiro/steering/`)
- Verify front-matter has `inclusion: always`
- Restart your AI assistant

### Skills Too Strict

- Customize the skill files for your workflow
- Add project-specific exceptions
- Change `inclusion: always` to `inclusion: manual` for optional skills

### Conflicts Between Skills

- User instructions always take precedence
- Skills override default AI behavior
- Later workspace rules override global rules

## Contributing

To contribute improvements:

1. Enhance existing skill workflows
2. Add new skills for uncovered scenarios
3. Improve clarity and examples
4. Share customizations that work well
5. Report issues or unclear guidance

## Support

- Original framework: https://github.com/obra/superpowers
- Kiro IDE: https://kiro.ai

## License

MIT License

Adapted from obra/superpowers by Jesse Vincent (@obra).
Integrated for Kiro IDE and compatible AI assistants.

## Changelog

### Version 1.0 (Current)
- 6 core skills covering full development lifecycle
- Adapted for Kiro IDE steering file format
- Added installation scripts for multiple AI assistants
- Comprehensive documentation and examples
- Quick reference guides
- Project-specific customization support

