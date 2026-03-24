---
inclusion: fileMatch
fileMatchPattern: "**/{routes,controllers,middleware,api,server,app,handler,service,repository}.{ts,js,py,go}"
---

# Senior Backend Engineer

Patterns for API design, database optimization, authentication, and microservices. Apply these conventions when building or reviewing backend code.

---

## API Design

- Design resources and operations first (OpenAPI spec or equivalent) before writing handlers
- Validate all input at the boundary using a schema library (e.g. Zod, Joi, Pydantic) — never trust raw request data
- Return consistent error shapes: `{ message, errors? }` with appropriate HTTP status codes
- Paginate all list endpoints using cursor-based pagination; cap `limit` with a maximum (e.g. 100)
- Use a centralized error handler middleware — do not scatter `try/catch` with inline `res.status()` calls

```typescript
// Input validation at the boundary
const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  role: z.enum(['user', 'admin']).default('user'),
});

app.post('/users', async (req, res) => {
  const body = CreateUserSchema.parse(req.body);
  const user = await userService.create(body);
  res.status(201).json(user);
});

// Centralized error handler
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  if (err instanceof z.ZodError) return res.status(400).json({ errors: err.errors });
  if (err instanceof NotFoundError) return res.status(404).json({ message: err.message });
  console.error(err);
  res.status(500).json({ message: 'Internal server error' });
});
```

---

## Database

- Add indexes for every common query pattern; use `EXPLAIN ANALYZE` to verify they are used
- Use partial indexes for soft-deleted or filtered subsets
- Use covering indexes (`INCLUDE`) to avoid table lookups on hot read paths
- Eliminate N+1 queries — use JOINs or batch loading, never query inside a loop
- Configure connection pooling explicitly; do not rely on defaults

```sql
-- Composite index for common filter + sort
CREATE INDEX idx_orders_user_status ON orders(user_id, status, created_at DESC);

-- Partial index for active records
CREATE INDEX idx_users_active_email ON users(email) WHERE deleted_at IS NULL;

-- Covering index to avoid heap fetch
CREATE INDEX idx_products_search ON products(category_id, price) INCLUDE (name, slug);
```

```typescript
// N+1 — BAD
for (const order of orders) {
  order.items = await db.query('SELECT * FROM order_items WHERE order_id = $1', [order.id]);
}

// Single JOIN — GOOD
const orders = await db.query(`
  SELECT o.*, json_agg(oi.*) AS items
  FROM orders o
  LEFT JOIN order_items oi ON oi.order_id = o.id
  WHERE o.user_id = $1
  GROUP BY o.id
`, [userId]);
```

```typescript
// Connection pool — configure explicitly
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

---

## Authentication

- Use short-lived access tokens (15m) paired with longer-lived refresh tokens (7d)
- Store refresh tokens in the database so they can be revoked
- Always use `bcrypt` (or equivalent) for password hashing — never plain SHA/MD5
- Reject invalid credentials with a generic message to prevent user enumeration

```typescript
const ACCESS_TOKEN_TTL = '15m';
const REFRESH_TOKEN_TTL = '7d';

async function login(email: string, password: string) {
  const user = await userRepo.findByEmail(email);
  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    throw new UnauthorizedError('Invalid credentials'); // same message for both failure cases
  }
  const accessToken = jwt.sign({ sub: user.id, role: user.role }, process.env.JWT_SECRET!, {
    expiresIn: ACCESS_TOKEN_TTL,
  });
  const refreshToken = await refreshTokenRepo.create(user.id, REFRESH_TOKEN_TTL);
  return { accessToken, refreshToken };
}
```

---

## Microservices

Choose communication patterns based on coupling and consistency requirements:

| Pattern | Use When | Trade-off |
|---------|----------|-----------|
| REST/HTTP | Request-response, CRUD | Simple; synchronous coupling |
| gRPC | High-throughput internal calls | Binary protocol; schema required |
| Message queue (RabbitMQ/SQS) | Async, fire-and-forget | Eventually consistent |
| Event streaming (Kafka) | Event sourcing, audit log | High throughput; operational complexity |

Wrap external service calls in a circuit breaker to prevent cascade failures:

```typescript
import CircuitBreaker from 'opossum';

const breaker = new CircuitBreaker(callExternalService, {
  timeout: 3000,
  errorThresholdPercentage: 50,
  resetTimeout: 30000,
});
breaker.fallback(() => cachedResponse);
```

---

## Performance Checklist

Before marking backend work complete, verify:

- [ ] All query patterns have supporting indexes (`EXPLAIN ANALYZE` confirms usage)
- [ ] No N+1 queries in any code path
- [ ] Connection pool configured with explicit limits
- [ ] Expensive reads are cached where appropriate
- [ ] All list endpoints are paginated with a maximum page size
- [ ] No synchronous blocking operations on the event loop
- [ ] Rate limiting applied to public-facing endpoints
- [ ] Request/response compression enabled
