---
inclusion: fileMatch
fileMatchPattern: ["**/*.test.*", "**/*.spec.*", "**/__tests__/**", "**/tests/**", "**/test/**"]
---

# TDD Guide

Apply this guide when writing tests, improving coverage, generating mocks/fixtures, or practicing red-green-refactor across Jest, Vitest, Pytest, JUnit, or Mocha.

## Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

If code was written before the test: delete it and start over. No exceptions.

---

## Red-Green-Refactor Cycle

1. **RED** — Write the smallest test that describes the next behavior
2. **Verify RED** — Run it; confirm it fails for the right reason (missing feature, not a typo or import error)
3. **GREEN** — Write the minimal code to make it pass; no extras
4. **Verify GREEN** — Run the full suite; new test passes, nothing else breaks
5. **REFACTOR** — Clean up (naming, duplication, structure) without adding behavior; keep tests green
6. **Repeat** — one behavior at a time

> If a test passes immediately on first run, it is testing existing behavior. Fix or delete the test.

---

## Test Writing Rules

- One behavior per test; one assertion per concept
- Descriptive names: `test_divide_by_zero_raises_value_error`, `it('returns 401 when token is expired')`
- Use real code; reach for mocks only when crossing I/O or external service boundaries
- Cover the happy path, error paths, and boundary conditions
- Tests must be deterministic — no `Date.now()`, `Math.random()`, or network calls without mocking

---

## Framework Reference

| Framework | Language | Single-run command |
|-----------|----------|--------------------|
| Jest | TS / JS | `npx jest --testPathPattern=<file>` |
| Vitest | TS / JS | `npx vitest run <file>` |
| Pytest | Python | `pytest -v <file>::<test>` |
| JUnit 5 | Java | `mvn test -Dtest=<Class>#<method>` |
| Mocha | JS | `npx mocha <file>` |

Always run the targeted test first (RED/GREEN), then the full suite before committing.

---

## Test Generation Examples

### Pytest

```python
# Source: math_utils.py
def divide(a: float, b: float) -> float:
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b

# Test: test_math_utils.py
import pytest
from math_utils import divide

class TestDivide:
    def test_positive_numbers(self):
        assert divide(10, 2) == 5.0

    def test_negative_numerator(self):
        assert divide(-10, 2) == -5.0

    def test_float_result(self):
        assert divide(1, 3) == pytest.approx(0.333, rel=1e-3)

    def test_divide_by_zero_raises(self):
        with pytest.raises(ValueError, match="Cannot divide by zero"):
            divide(10, 0)

    def test_zero_numerator(self):
        assert divide(0, 5) == 0.0
```

### Jest / Vitest

```typescript
// Source: auth.ts
export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, 12);
}

// Test: auth.test.ts
describe('hashPassword', () => {
  it('returns a bcrypt hash', async () => {
    const hash = await hashPassword('secret123');
    expect(hash).toMatch(/^\$2[aby]\$/);
  });

  it('produces different hashes for the same input', async () => {
    const h1 = await hashPassword('secret');
    const h2 = await hashPassword('secret');
    expect(h1).not.toBe(h2);
  });

  it('throws on empty password', async () => {
    await expect(hashPassword('')).rejects.toThrow();
  });
});
```

---

## Fixture / Factory Patterns

### TypeScript (faker-js)

```typescript
// factories/user.factory.ts
import { faker } from '@faker-js/faker';

export const createUser = (overrides = {}) => ({
  id: faker.string.uuid(),
  name: faker.person.fullName(),
  email: faker.internet.email(),
  role: 'user' as const,
  ...overrides,
});
```

### Python (factory_boy)

```python
# factories/user_factory.py
import factory
from faker import Faker

fake = Faker()

class UserFactory(factory.Factory):
    class Meta:
        model = dict

    id = factory.LazyFunction(lambda: str(fake.uuid4()))
    name = factory.LazyFunction(fake.name)
    email = factory.LazyFunction(fake.email)
    role = "user"
```

---

## Coverage Analysis

Prioritize gaps by risk:

- **P0 — Critical**: uncovered error paths, auth flows, payment logic → fix first
- **P1 — High**: uncovered branches in core business logic
- **P2 — Low**: utility/helper functions with low risk

**Generate coverage reports:**

```bash
# Jest
npx jest --coverage

# Vitest
npx vitest run --coverage

# Pytest
pytest --cov=src --cov-report=term-missing
```

Target: cover all P0 gaps before claiming a feature complete.

---

## TDD Completion Checklist

Before marking any task done:

- [ ] Every new function/method has a test written before implementation
- [ ] Each test was observed to fail (RED confirmed)
- [ ] Failure was for the expected reason — missing feature, not a syntax error
- [ ] Minimal code was written to pass each test
- [ ] Full test suite passes (GREEN confirmed)
- [ ] No new warnings or errors in output
- [ ] Mocks used only at I/O / external service boundaries
- [ ] Edge cases and error paths are covered

Cannot check every box? TDD was skipped. Start over.
