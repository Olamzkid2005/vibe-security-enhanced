---
inclusion: always
---

# Senior Fullstack Engineer

Fullstack development guidance covering stack selection, project structure, architecture patterns, and common pitfalls.

---

## Stack Selection

| Requirement | Recommended Stack |
|-------------|------------------|
| SEO-critical or content site | Next.js (App Router, SSR/SSG) |
| Internal dashboard or SPA | React + Vite |
| API-first backend (Python) | FastAPI |
| API-first backend (Node) | Fastify or NestJS |
| Enterprise scale | NestJS + PostgreSQL |
| Rapid prototype | Next.js API routes |
| Document-heavy / flexible schema | MongoDB |
| Relational / complex queries | PostgreSQL |

---

## Project Structure

### Next.js (App Router)

```
my-app/
├── app/
│   ├── layout.tsx          # Root layout
│   ├── page.tsx            # Home page
│   ├── globals.css         # Tailwind + CSS variables
│   └── api/health/route.ts # Health check route
├── components/
│   ├── ui/                 # Primitives: Button, Input, Card
│   └── layout/             # Header, Footer, Sidebar
├── hooks/                  # Custom hooks: useDebounce, useLocalStorage
├── lib/                    # Utilities (cn), constants, config
├── types/                  # Shared TypeScript interfaces
├── tailwind.config.ts
├── next.config.js
└── package.json
```

### FastAPI + React (Monorepo)

```
my-project/
├── backend/
│   ├── app/
│   │   ├── main.py
│   │   ├── routers/        # Route handlers grouped by domain
│   │   ├── models/         # SQLAlchemy / Pydantic models
│   │   ├── schemas/        # Request/response schemas
│   │   └── database.py     # DB session and connection
│   └── requirements.txt
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   └── api/            # API client functions
│   └── package.json
└── docker-compose.yml
```

---

## Architecture Patterns

### Frontend: Container / Presentational Split

Keep data-fetching logic out of rendering components.

```typescript
// Container: owns data and state
export function UserListContainer() {
  const { data, isLoading } = useUsers();
  return <UserList users={data} isLoading={isLoading} />;
}

// Presentational: pure rendering, no side effects
export function UserList({ users, isLoading }: UserListProps) {
  if (isLoading) return <Skeleton />;
  return <ul>{users.map(u => <UserItem key={u.id} user={u} />)}</ul>;
}
```

### Backend: Clean / Layered Architecture

```
src/
├── domain/          # Business entities and rules — no external dependencies
├── application/     # Use cases — depends only on domain
├── infrastructure/  # DB, external APIs — implements application interfaces
└── presentation/    # HTTP handlers — calls application layer only
```

Dependencies flow inward only. Infrastructure never imports from presentation.

### Authentication: JWT + Refresh Token Flow

```
1. Login  → short-lived access token (15 min) + long-lived refresh token (7 days)
2. Requests → Bearer access token in Authorization header
3. 401 received → use refresh token to obtain new access token silently
4. Refresh token expired → redirect to login
```

Store refresh tokens in `httpOnly` cookies. Never store tokens in `localStorage`.

---

## Code Style Rules

- **TypeScript strict mode** — always enable `"strict": true` in `tsconfig.json`
- **Co-locate tests** — place test files next to the code they test (`foo.test.ts` beside `foo.ts`)
- **Single responsibility** — one concern per file; split when a file exceeds ~200 lines
- **No barrel re-exports** for large modules — they hurt tree-shaking and build times
- **Environment variables** — validate at startup with a schema (e.g., `zod`); never read `process.env` inline across the codebase
- **Error handling** — always handle async errors explicitly; avoid silent `catch (() => {})` blocks

---

## Common Issues and Fixes

| Issue | Fix |
|-------|-----|
| N+1 queries | Use DataLoader, eager loading, or `select` with joins |
| Slow frontend builds | Audit bundle size; lazy-load heavy routes and components |
| Auth complexity | Prefer Auth.js, Clerk, or a dedicated auth service over rolling your own |
| TypeScript errors | Enable strict mode; fix errors at the source, not with `as` casts |
| CORS issues | Configure CORS middleware on the server; never disable it globally in production |
| Hydration mismatch (Next.js) | Ensure server and client render identical initial HTML; avoid `Date.now()` or `Math.random()` during render |
| Secrets in source | Use `.env` files locally; inject via environment in CI/CD; never commit secrets |

---

## New Project Checklist

- [ ] Stack chosen based on requirements matrix
- [ ] Project scaffolded with correct folder structure
- [ ] TypeScript strict mode enabled
- [ ] Linter and formatter configured (ESLint + Prettier or Biome)
- [ ] Environment variable validation in place
- [ ] Authentication strategy decided before writing any protected routes
- [ ] CI pipeline runs lint, type-check, and tests on every PR
