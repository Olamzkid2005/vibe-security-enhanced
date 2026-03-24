---
inclusion: always
---

# Brainstorming Skill - Design Before Implementation

Apply this skill BEFORE any creative work: new features, components, functionality additions, or behavior changes.

## Hard Gate

Do NOT write code, scaffold projects, or take any implementation action until a design has been presented and the user has explicitly approved it. No exceptions, regardless of perceived simplicity.

## Anti-Pattern: "This Is Too Simple To Need A Design"

Every task goes through this process. Simple projects are where unexamined assumptions cause the most wasted work. The design can be brief (a few sentences), but it MUST be presented and approved before proceeding.

## Process (in order)

1. **Explore context** — read relevant files, docs, recent commits before asking questions
2. **Ask one clarifying question at a time** — focus on purpose, constraints, and success criteria
3. **Propose 2-3 approaches** — include trade-offs and a clear recommendation
4. **Present design in sections** — scale depth to complexity; get approval after each section
5. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit
6. **User review gate** — wait for explicit approval before proceeding
7. **Transition to implementation** — create a detailed implementation plan

## Understanding the Idea

- Check current project state first (files, docs, recent commits)
- If the request spans multiple independent subsystems, flag it immediately and help decompose into sub-projects
- Ask questions one at a time; prefer multiple-choice over open-ended
- Focus on: purpose, constraints, success criteria

## Exploring Approaches

- Always propose 2-3 distinct approaches with trade-offs
- Lead with your recommended option and explain why
- Be conversational, not exhaustive

## Presenting the Design

- Cover: architecture, components, data flow, error handling, testing strategy
- Scale each section to its complexity (a few sentences up to ~200 words)
- Ask after each section: "Does this look right?"
- Be ready to revise if something doesn't make sense

## Design Principles

- Break the system into units with a single clear responsibility
- Units communicate through well-defined interfaces
- Each unit must be independently understandable and testable
- For each unit, answer: what does it do, how is it used, what does it depend on?

## Working in Existing Codebases

- Explore the current structure before proposing changes
- Follow established patterns and conventions
- Include targeted improvements only where existing code directly affects the work
- Do not propose unrelated refactoring

## After Design Approval

- Write the validated design to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
- Commit the design document
- Ask the user to review the written spec:
  > "Spec written and committed to `<path>`. Please review it and let me know if you'd like any changes before we move to the implementation plan."
- Wait for approval. Make requested changes. Only proceed once the user confirms.
- Then create a detailed implementation plan with bite-sized tasks (2–5 minutes each)

## Key Principles

- One question at a time — never stack multiple questions
- YAGNI — remove anything not needed for the stated goal
- Incremental validation — present, get approval, then proceed
- Prefer multiple-choice questions over open-ended when possible
