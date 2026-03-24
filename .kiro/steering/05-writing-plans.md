---
inclusion: always
---

# Writing Plans

Apply before touching code when you have a spec, requirements, or a multi-step task.

## Core Principle

Write plans assuming zero codebase context. Every task must include exact file paths, complete code, exact commands, and expected output. No ambiguity.

**Principles:** DRY. YAGNI. TDD. Frequent commits.

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`

## Before You Start

**Scope check:** If the spec spans multiple independent subsystems, split into separate plans — one per subsystem. Each plan must produce working, testable software on its own.

**File map:** Before defining tasks, list every file to be created or modified and its single responsibility. Files that change together should live together. In existing codebases, follow established patterns.

## Plan Document Header

Every plan must open with:

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence — what this builds]

**Architecture:** [2–3 sentences — approach and key decisions]

**Tech Stack:** [Key technologies/libraries]

**Files:**
- Create: `exact/path/to/new-file.ts`
- Modify: `exact/path/to/existing.ts`
- Test: `tests/exact/path/to/file.test.ts`

---
```

## Task Structure

Each task maps to one component or concern. Steps are 2–5 minutes each.

````markdown
### Task N: [Component Name]

**Files:**
- Create/Modify: `exact/path/to/file.ts`
- Test: `tests/exact/path/to/file.test.ts`

- [ ] **Step 1: Write the failing test**
  ```ts
  it('should do X when Y', () => {
    const result = fn(input);
    expect(result).toBe(expected);
  });
  ```

- [ ] **Step 2: Run test — confirm it fails**
  Run: `npx vitest run tests/path/file.test.ts`
  Expected: FAIL — "fn is not defined" (or similar)

- [ ] **Step 3: Write minimal implementation**
  ```ts
  export function fn(input: T): R {
    return expected;
  }
  ```

- [ ] **Step 4: Run test — confirm it passes**
  Run: `npx vitest run tests/path/file.test.ts`
  Expected: PASS

- [ ] **Step 5: Commit**
  ```bash
  git add tests/path/file.test.ts src/path/file.ts
  git commit -m "feat: add [component name]"
  ```
````

## Hard Rules

- Exact file paths — never relative or vague
- Complete code in the plan — not "add validation here"
- Exact commands with expected output for every run step
- Every task follows RED → GREEN → COMMIT
- No step should take more than 5 minutes; split if it does

## After Writing the Plan

Save the file, then prompt:

> "Plan saved to `docs/superpowers/plans/<filename>.md`. Ready to execute tasks?"

Execute tasks sequentially. Do not skip ahead or batch steps.
