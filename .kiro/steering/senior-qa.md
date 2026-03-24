---
inclusion: fileMatch
fileMatchPattern: "**/{*.test.*,*.spec.*,__tests__/**,e2e/**,cypress/**,playwright/**}"
---

# Senior QA Engineer

Test automation, coverage analysis, and quality assurance for React and Next.js applications.

---

## Core Principles

- Write tests before implementation (TDD: RED → GREEN → REFACTOR)
- Test behavior, not implementation details
- Prefer `userEvent` over `fireEvent` for realistic interaction simulation
- Use `getByRole` and semantic queries over `getByTestId`
- One assertion focus per test; descriptive test names
- Mock at the network boundary (MSW), not at the module level

---

## Unit Tests — React Testing Library

```typescript
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { server } from '../mocks/server';
import { http, HttpResponse } from 'msw';

describe('Button', () => {
  it('calls onClick when clicked', async () => {
    const handleClick = jest.fn();
    render(<Button onClick={handleClick}>Submit</Button>);
    await userEvent.click(screen.getByRole('button', { name: /submit/i }));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('is disabled while loading', () => {
    render(<Button loading>Submit</Button>);
    expect(screen.getByRole('button')).toBeDisabled();
  });
});

// Async component with MSW
it('shows error on fetch failure', async () => {
  server.use(http.get('/api/users/:id', () => HttpResponse.error()));
  render(<UserProfile userId="123" />);
  await waitFor(() => expect(screen.getByRole('alert')).toBeInTheDocument());
});
```

---

## API Mocking — MSW

Use MSW v2 syntax. Mock at the network layer, not module imports.

```typescript
// mocks/handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('/api/users/:id', ({ params }) =>
    HttpResponse.json({ id: params.id, name: '[name]', email: '[email]' })
  ),
  http.post('/api/users', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json({ id: 'new-id', ...body }, { status: 201 });
  }),
];

// mocks/server.ts
import { setupServer } from 'msw/node';
export const server = setupServer(...handlers);

// jest.setup.ts
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

---

## Test Fixtures

```typescript
// factories/user.factory.ts
import { faker } from '@faker-js/faker';

export function createUser(overrides = {}) {
  return {
    id: faker.string.uuid(),
    name: faker.person.fullName(),
    email: faker.internet.email(),
    role: 'user' as const,
    createdAt: faker.date.past(),
    ...overrides,
  };
}
```

---

## E2E Testing — Playwright (Page Object Model)

```typescript
// e2e/pages/LoginPage.ts
export class LoginPage {
  constructor(private page: Page) {}

  async goto() { await this.page.goto('/login'); }

  async login(email: string, password: string) {
    await this.page.fill('[name=email]', email);
    await this.page.fill('[name=password]', password);
    await this.page.click('[type=submit]');
  }

  async expectError(message: string) {
    await expect(this.page.getByRole('alert')).toContainText(message);
  }
}

// e2e/tests/auth.spec.ts
test('redirects to dashboard after valid login', async ({ page }) => {
  const loginPage = new LoginPage(page);
  await loginPage.goto();
  await loginPage.login('[email]', '[password]');
  await expect(page).toHaveURL('/dashboard');
});
```

---

## Coverage Analysis

Prioritize gaps by risk, not by line count.

```
P0 — Critical (uncovered error/auth paths):   fix immediately
P1 — High-value (core logic branches):        fix before merge
P2 — Low-risk (utilities, formatting):        fix opportunistically
```

**Run coverage:**
```bash
npm test -- --coverage --coverageReporters=lcov,json
```

**Enforce thresholds in Jest config:**
```json
{
  "coverageThreshold": {
    "global": { "branches": 80, "functions": 80, "lines": 80 }
  }
}
```

---

## QA Checklist

- [ ] Unit tests cover all business logic and branches
- [ ] Integration tests cover API endpoints and data flows
- [ ] E2E tests cover critical user flows (auth, checkout, key forms)
- [ ] Error states tested: network failure, validation errors, empty states
- [ ] Loading and async states tested
- [ ] Accessibility tested: keyboard navigation, ARIA roles, screen reader labels
- [ ] Coverage meets threshold (80%+ branches, functions, lines)
- [ ] Tests run in CI on every PR; no flaky tests merged
