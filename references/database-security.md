# Database Security

## Overview

Database security encompasses access control, query security, transaction integrity, and data protection. AI-generated code frequently introduces broken access control (disabled RLS), insecure queries, and transaction issues.

## Critical Patterns to Detect

### 1. Supabase Row-Level Security (RLS) Disabled

**Vulnerable patterns:**

```sql
-- WRONG: RLS disabled on sensitive table
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email TEXT,
  password_hash TEXT,
  balance DECIMAL
);
-- No ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- WRONG: Overly permissive policy
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "allow_all" ON users FOR ALL USING (true);

-- WRONG: No WITH CHECK clause
CREATE POLICY "select_own" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "update_own" ON users FOR UPDATE USING (auth.uid() = id);
-- Missing WITH CHECK - user can update to any id!
```

**Impact**: With RLS disabled or misconfigured, anyone with the anon key can read, modify, or delete all data in the table, regardless of authentication.

**Proof of concept**:
```javascript
// Attacker uses anon key to access all users
const { data } = await supabase
  .from('users')
  .select('*')
// Returns all users if RLS is disabled
```

**Fix:**

```sql
-- CORRECT: Enable RLS and create proper policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- SELECT: Users can only read their own data
CREATE POLICY "users_select_own" ON users
  FOR SELECT
  USING (auth.uid() = id);

-- INSERT: Users can only insert their own data
CREATE POLICY "users_insert_own" ON users
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- UPDATE: Users can only update their own data, and can't change their ID
CREATE POLICY "users_update_own" ON users
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- DELETE: Users can only delete their own data
CREATE POLICY "users_delete_own" ON users
  FOR DELETE
  USING (auth.uid() = id);

-- Admin policy (separate from user policies)
CREATE POLICY "admins_all_access" ON users
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );
```

### 2. Supabase Service Role Key Exposure

**Vulnerable patterns:**

```javascript
// WRONG: Service role key in client code
const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.NEXT_PUBLIC_SUPABASE_SERVICE_KEY  // CRITICAL: Bypasses RLS!
);

// WRONG: Service role key in frontend environment variable
NEXT_PUBLIC_SUPABASE_KEY=eyJhbGc...service_role_key...
```

**Impact**: The service role key bypasses ALL Row-Level Security policies. Anyone who extracts it from the client bundle can read, modify, or delete any data in the database.

**Fix:**

```javascript
// CORRECT: Use anon key in client code
const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY  // Public, safe to expose
);

// CORRECT: Service role key only in server-side code
// pages/api/admin/users.js
import { createClient } from '@supabase/supabase-js';

const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY  // Server-side only, never exposed
);

export default async function handler(req, res) {
  // Verify user is admin
  const token = req.headers.authorization?.replace('Bearer ', '');
  const { data: { user } } = await supabase.auth.getUser(token);
  
  if (!user || !await isAdmin(user.id)) {
    return res.status(403).json({ error: 'Unauthorized' });
  }
  
  // Now safe to use admin client
  const { data } = await supabaseAdmin.from('users').select('*');
  res.json(data);
}
```

### 3. Firebase Security Rules Disabled

**Vulnerable patterns:**

```javascript
// WRONG: Allow all access
{
  "rules": {
    ".read": true,
    ".write": true
  }
}

// WRONG: No authentication check
{
  "rules": {
    "users": {
      "$uid": {
        ".read": true,
        ".write": true
      }
    }
  }
}
```

**Impact**: Anyone can read and write all data in the database.

**Fix:**

```javascript
// CORRECT: Proper Firebase Security Rules
{
  "rules": {
    "users": {
      "$uid": {
        // Users can only read their own data
        ".read": "$uid === auth.uid",
        // Users can only write their own data
        ".write": "$uid === auth.uid",
        // Validate data structure
        ".validate": "newData.hasChildren(['name', 'email'])",
        
        "name": {
          ".validate": "newData.isString() && newData.val().length > 0 && newData.val().length <= 100"
        },
        "email": {
          ".validate": "newData.isString() && newData.val().matches(/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$/i)"
        },
        // Prevent modification of sensitive fields
        "balance": {
          ".write": false  // Only server can modify balance
        },
        "role": {
          ".write": false  // Only server can modify role
        }
      }
    },
    
    "orders": {
      "$orderId": {
        // Users can read their own orders
        ".read": "data.child('userId').val() === auth.uid",
        // Users can create orders
        ".write": "!data.exists() && newData.child('userId').val() === auth.uid",
        // Validate order structure
        ".validate": "newData.hasChildren(['userId', 'amount', 'status'])",
        
        "userId": {
          ".validate": "newData.val() === auth.uid"
        },
        "amount": {
          ".validate": "newData.isNumber() && newData.val() > 0"
        },
        "status": {
          // Only server can set status
          ".write": false
        }
      }
    }
  }
}
```

### 4. Convex Missing Authentication

**Vulnerable patterns:**

```typescript
// WRONG: No authentication check
export const getUser = query({
  args: { userId: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db.get(args.userId);
  },
});

// WRONG: Trusting client-provided userId
export const updateBalance = mutation({
  args: { userId: v.string(), amount: v.number() },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.userId, { balance: args.amount });
  },
});
```

**Impact**: Anyone can read or modify any user's data.

**Fix:**

```typescript
// CORRECT: Verify authentication and authorization
import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

export const getUser = query({
  args: { userId: v.string() },
  handler: async (ctx, args) => {
    // Get authenticated user
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) {
      throw new Error("Not authenticated");
    }
    
    // Verify user can only access their own data
    if (identity.subject !== args.userId) {
      throw new Error("Unauthorized");
    }
    
    return await ctx.db.get(args.userId);
  },
});

export const updateBalance = mutation({
  args: { amount: v.number() },
  handler: async (ctx, args) => {
    // Get authenticated user
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) {
      throw new Error("Not authenticated");
    }
    
    // Use authenticated user's ID, not client-provided
    const userId = identity.subject;
    
    // Additional validation
    if (args.amount < 0) {
      throw new Error("Amount must be positive");
    }
    
    await ctx.db.patch(userId, { balance: args.amount });
  },
});

// Helper function for role-based access
async function requireRole(ctx: any, role: string) {
  const identity = await ctx.auth.getUserIdentity();
  if (!identity) {
    throw new Error("Not authenticated");
  }
  
  const user = await ctx.db.get(identity.subject);
  if (user?.role !== role) {
    throw new Error("Insufficient permissions");
  }
  
  return user;
}

export const getAllUsers = query({
  handler: async (ctx) => {
    await requireRole(ctx, "admin");
    return await ctx.db.query("users").collect();
  },
});
```

### 5. SQL Injection in Raw Queries

**Vulnerable patterns:**

```python
# Python - SQLAlchemy - WRONG: Using text() with string interpolation
from sqlalchemy import text

def get_user(username):
    query = text(f"SELECT * FROM users WHERE username = '{username}'")
    return db.session.execute(query).fetchone()

# WRONG: execute() with string formatting
def search_products(keyword):
    query = f"SELECT * FROM products WHERE name LIKE '%{keyword}%'"
    return db.session.execute(query).fetchall()
```

**Fix:**

```python
# Python - SQLAlchemy - CORRECT: Use parameterized queries
from sqlalchemy import text

def get_user(username):
    query = text("SELECT * FROM users WHERE username = :username")
    return db.session.execute(query, {"username": username}).fetchone()

# CORRECT: Use ORM
from sqlalchemy import select

def get_user(username):
    stmt = select(User).where(User.username == username)
    return db.session.execute(stmt).scalar_one_or_none()

def search_products(keyword):
    stmt = select(Product).where(Product.name.like(f"%{keyword}%"))
    return db.session.execute(stmt).scalars().all()
```

### 6. Insecure Database Connections

**Vulnerable patterns:**

```python
# Python - WRONG: Unencrypted database connection
DATABASE_URL = "postgresql://user:password@host:5432/db"

# WRONG: Disabling SSL verification
DATABASE_URL = "postgresql://user:password@host:5432/db?sslmode=disable"

# WRONG: Database credentials in code
db = psycopg2.connect(
    host="prod-db.example.com",
    user="admin",
    password="MyP@ssw0rd123",
    database="production"
)
```

**Fix:**

```python
# Python - CORRECT: Encrypted connection with SSL
import os

DATABASE_URL = os.environ['DATABASE_URL']
# Should be: postgresql://user:password@host:5432/db?sslmode=require

# CORRECT: Verify SSL certificate
from sqlalchemy import create_engine

engine = create_engine(
    DATABASE_URL,
    connect_args={
        'sslmode': 'verify-full',
        'sslrootcert': '/path/to/ca-cert.pem'
    }
)

# CORRECT: Use connection pooling with limits
engine = create_engine(
    DATABASE_URL,
    pool_size=10,
    max_overflow=20,
    pool_timeout=30,
    pool_recycle=3600,
    pool_pre_ping=True  # Verify connections before use
)
```

### 7. Transaction Isolation Issues

**Vulnerable patterns:**

```python
# Python - WRONG: No transaction isolation
def transfer_funds(from_user_id, to_user_id, amount):
    from_user = db.query(User).get(from_user_id)
    to_user = db.query(User).get(to_user_id)
    
    # Race condition: another transaction can modify balances here
    if from_user.balance >= amount:
        from_user.balance -= amount
        to_user.balance += amount
        db.commit()

# WRONG: Read committed isolation (default) for critical operations
def place_order(user_id, product_id, quantity):
    product = db.query(Product).get(product_id)
    if product.stock >= quantity:
        # Another transaction can buy the same stock here
        product.stock -= quantity
        order = Order(user_id=user_id, product_id=product_id, quantity=quantity)
        db.add(order)
        db.commit()
```

**Impact**: Race conditions can lead to double-spending, overselling, or data corruption.

**Fix:**

```python
# Python - CORRECT: Use SELECT FOR UPDATE for row locking
from sqlalchemy import select

def transfer_funds(from_user_id, to_user_id, amount):
    with db.begin():  # Start transaction
        # Lock rows for update
        from_user = db.session.execute(
            select(User).where(User.id == from_user_id).with_for_update()
        ).scalar_one()
        
        to_user = db.session.execute(
            select(User).where(User.id == to_user_id).with_for_update()
        ).scalar_one()
        
        if from_user.balance < amount:
            raise InsufficientFundsError()
        
        from_user.balance -= amount
        to_user.balance += amount
        # Commit happens automatically at end of with block

# CORRECT: Use serializable isolation for critical operations
from sqlalchemy import create_engine

engine = create_engine(
    DATABASE_URL,
    isolation_level="SERIALIZABLE"
)

def place_order(user_id, product_id, quantity):
    with db.begin():
        product = db.session.execute(
            select(Product).where(Product.id == product_id).with_for_update()
        ).scalar_one()
        
        if product.stock < quantity:
            raise OutOfStockError()
        
        product.stock -= quantity
        order = Order(user_id=user_id, product_id=product_id, quantity=quantity)
        db.session.add(order)
```

### 8. Exposed Database Credentials

**Vulnerable patterns:**

```python
# WRONG: Database URL in error messages
try:
    db.connect(DATABASE_URL)
except Exception as e:
    print(f"Failed to connect to {DATABASE_URL}: {e}")

# WRONG: Database credentials in logs
logger.info(f"Connecting to database: {DATABASE_URL}")

# WRONG: Database URL in client-side code
const API_URL = "postgresql://user:pass@host:5432/db";
```

**Fix:**

```python
# CORRECT: Generic error messages
try:
    db.connect(DATABASE_URL)
except Exception as e:
    logger.error("Database connection failed", exc_info=True)
    raise Exception("Database connection failed")

# CORRECT: Redact credentials from logs
import re

def redact_credentials(url):
    return re.sub(r'://([^:]+):([^@]+)@', r'://\1:***@', url)

logger.info(f"Connecting to database: {redact_credentials(DATABASE_URL)}")
```

### 9. Missing Database Indexes

**Vulnerable patterns:**

```sql
-- WRONG: No index on frequently queried columns
CREATE TABLE orders (
  id UUID PRIMARY KEY,
  user_id UUID,
  product_id UUID,
  created_at TIMESTAMP
);
-- Queries like "WHERE user_id = ?" will be slow

-- WRONG: No index on foreign keys
CREATE TABLE order_items (
  id UUID PRIMARY KEY,
  order_id UUID,
  product_id UUID
);
```

**Impact**: Slow queries can lead to DoS, and missing indexes on security-critical columns can make authorization checks slow.

**Fix:**

```sql
-- CORRECT: Add indexes on frequently queried columns
CREATE TABLE orders (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  product_id UUID NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_product_id ON orders(product_id);
CREATE INDEX idx_orders_created_at ON orders(created_at);

-- Composite index for common query patterns
CREATE INDEX idx_orders_user_created ON orders(user_id, created_at DESC);

-- CORRECT: Add indexes on foreign keys
CREATE TABLE order_items (
  id UUID PRIMARY KEY,
  order_id UUID NOT NULL,
  product_id UUID NOT NULL
);

CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
```

### 10. Sensitive Data in Database

**Vulnerable patterns:**

```sql
-- WRONG: Storing sensitive data in plain text
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email TEXT,
  password TEXT,  -- Plain text password!
  ssn TEXT,       -- Plain text SSN!
  credit_card TEXT  -- Plain text credit card!
);

-- WRONG: No data retention policy
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY,
  user_id UUID,
  action TEXT,
  details JSONB,
  created_at TIMESTAMP
);
-- Logs kept forever, including sensitive data
```

**Fix:**

```sql
-- CORRECT: Hash passwords, encrypt sensitive data
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,  -- Hashed with bcrypt/Argon2
  ssn_encrypted BYTEA,           -- Encrypted with application-level encryption
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- CORRECT: Data retention policy
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  action TEXT NOT NULL,
  details JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Automatically delete old logs
CREATE OR REPLACE FUNCTION delete_old_audit_logs()
RETURNS void AS $$
BEGIN
  DELETE FROM audit_logs WHERE created_at < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

-- Schedule cleanup (using pg_cron or application-level job)
SELECT cron.schedule('cleanup-audit-logs', '0 2 * * *', 'SELECT delete_old_audit_logs()');
```

## Quick Fix Patterns

### Pattern 1: RLS Disabled → Enable RLS with Policies

**Detection**: Check Supabase tables for missing `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`

**Fix (diff format)**:
```diff
+ -- Enable RLS on the table
+ ALTER TABLE users ENABLE ROW LEVEL SECURITY;
+ 
+ -- Add policy for users to read their own data
+ CREATE POLICY "users_select_own" ON users
+   FOR SELECT
+   USING (auth.uid() = id);
+ 
+ -- Add policy for users to update their own data
+ CREATE POLICY "users_update_own" ON users
+   FOR UPDATE
+   USING (auth.uid() = id)
+   WITH CHECK (auth.uid() = id);
```

**Manual steps**:
1. Run `ALTER TABLE <table_name> ENABLE ROW LEVEL SECURITY;` for each table
2. Create SELECT policy: `CREATE POLICY "select_own" ON <table> FOR SELECT USING (auth.uid() = user_id);`
3. Create INSERT policy with WITH CHECK clause
4. Create UPDATE policy with both USING and WITH CHECK
5. Create DELETE policy if needed
6. Test with authenticated user to verify access control works
7. Test with different user to verify they can't access other users' data

### Pattern 2: Service Role in Client → Move to Server

**Detection**: Search for `NEXT_PUBLIC_SUPABASE_SERVICE`, `VITE_SUPABASE_SERVICE`, service role key in client code

**Fix (diff format)**:
```diff
# .env
- NEXT_PUBLIC_SUPABASE_KEY=eyJhbGc...service_role...
+ NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGc...anon...
+ SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...service_role...
```

```diff
// lib/supabase.js (client-side)
- const supabase = createClient(url, process.env.NEXT_PUBLIC_SUPABASE_SERVICE_KEY);
+ const supabase = createClient(url, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY);
```

```diff
// pages/api/admin.js (NEW FILE - server-side only)
+ import { createClient } from '@supabase/supabase-js';
+ 
+ const supabaseAdmin = createClient(
+   process.env.SUPABASE_URL,
+   process.env.SUPABASE_SERVICE_ROLE_KEY
+ );
+ 
+ export default async function handler(req, res) {
+   // Verify admin authentication first
+   const { data } = await supabaseAdmin.from('users').select('*');
+   res.json(data);
+ }
```

**Manual steps**:
1. Remove service role key from all client-side environment variables
2. Add service role key to server-side environment variables only
3. Replace client-side service role usage with anon key
4. Create API routes for operations that need service role
5. Add authentication/authorization checks in API routes
6. Rotate the exposed service role key in Supabase dashboard
7. Test that client can no longer bypass RLS
8. Rebuild and redeploy to remove key from client bundle

### Pattern 3: SQL Injection → Parameterized Query

**Detection**: Search for f-strings, string concatenation, or `.format()` in SQL queries

**Fix (diff format)**:
```diff
- query = f"SELECT * FROM users WHERE username = '{username}'"
- result = db.execute(query)
+ query = "SELECT * FROM users WHERE username = ?"
+ result = db.execute(query, (username,))
```

```diff
# SQLAlchemy
- from sqlalchemy import text
- query = text(f"SELECT * FROM users WHERE username = '{username}'")
+ query = text("SELECT * FROM users WHERE username = :username")
+ result = db.session.execute(query, {"username": username})

# Or use ORM (preferred)
+ from sqlalchemy import select
+ stmt = select(User).where(User.username == username)
+ result = db.session.execute(stmt).scalar_one_or_none()
```

**Manual steps**:
1. Find all SQL queries using string interpolation
2. Replace with parameterized queries using `?` or `:param` placeholders
3. Pass parameters as separate arguments to execute()
4. For ORMs, use query builder methods instead of raw SQL
5. Test with malicious input: `username = "admin' OR '1'='1"`
6. Verify query fails safely instead of returning unauthorized data

### Pattern 4: No Transaction Lock → SELECT FOR UPDATE

**Detection**: Critical operations (balance updates, stock management) without row locking

**Fix (diff format)**:
```diff
  def transfer_funds(from_user_id, to_user_id, amount):
-     from_user = db.query(User).get(from_user_id)
-     to_user = db.query(User).get(to_user_id)
+     with db.begin():
+         from_user = db.session.execute(
+             select(User).where(User.id == from_user_id).with_for_update()
+         ).scalar_one()
+         
+         to_user = db.session.execute(
+             select(User).where(User.id == to_user_id).with_for_update()
+         ).scalar_one()
          
          if from_user.balance >= amount:
              from_user.balance -= amount
              to_user.balance += amount
-             db.commit()
```

**Manual steps**:
1. Identify critical operations that modify financial data or inventory
2. Wrap in transaction: `with db.begin():`
3. Add `.with_for_update()` to SELECT queries
4. Ensure transaction commits only after all checks pass
5. Test with concurrent requests to verify no race conditions
6. Monitor for deadlocks and adjust lock order if needed

## Framework-Specific Guidance

### Supabase (RLS Policies, anon vs service key)

**RLS Policy Patterns**:
```sql
-- Pattern 1: User owns the row (user_id column)
CREATE POLICY "users_own_data" ON table_name
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Pattern 2: Public read, authenticated write
CREATE POLICY "public_read" ON table_name
  FOR SELECT
  USING (true);

CREATE POLICY "authenticated_write" ON table_name
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- Pattern 3: Role-based access
CREATE POLICY "admin_all_access" ON table_name
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- Pattern 4: Relationship-based access (e.g., team members)
CREATE POLICY "team_members_access" ON projects
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM team_members
      WHERE team_id = projects.team_id
      AND user_id = auth.uid()
    )
  );

-- Pattern 5: Time-based access
CREATE POLICY "active_subscriptions" ON premium_content
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM subscriptions
      WHERE user_id = auth.uid()
      AND expires_at > NOW()
    )
  );
```

**Client vs Server Usage**:
```typescript
// Client-side (uses anon key, respects RLS)
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

// User can only access their own data
const { data } = await supabase
  .from('users')
  .select('*')
  .eq('id', user.id);

// Server-side admin operations (bypasses RLS)
// pages/api/admin/users.ts
import { createClient } from '@supabase/supabase-js';

const supabaseAdmin = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

export default async function handler(req, res) {
  // CRITICAL: Verify admin authentication first
  const token = req.headers.authorization?.replace('Bearer ', '');
  const { data: { user } } = await supabase.auth.getUser(token);
  
  if (!user || !await isAdmin(user.id)) {
    return res.status(403).json({ error: 'Unauthorized' });
  }
  
  // Now safe to use admin client
  const { data } = await supabaseAdmin.from('users').select('*');
  res.json(data);
}
```

### Firebase (Security Rules)

**Firestore Security Rules Patterns**:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isOwner(userId) || isAdmin();
      allow create: if isAuthenticated() && isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if isAdmin();
      
      // Prevent modification of sensitive fields
      allow update: if isOwner(userId) && 
                      !request.resource.data.diff(resource.data).affectedKeys().hasAny(['role', 'balance']);
    }
    
    // Orders collection
    match /orders/{orderId} {
      allow read: if isAuthenticated() && 
                    resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && 
                      request.resource.data.userId == request.auth.uid &&
                      request.resource.data.status == 'pending';
      // Only server can update order status
      allow update: if false;
      allow delete: if false;
    }
    
    // Public content
    match /posts/{postId} {
      allow read: if true;
      allow create: if isAuthenticated();
      allow update, delete: if isAuthenticated() && 
                              resource.data.authorId == request.auth.uid;
    }
  }
}
```

### Prisma (Row-level security, middleware)

**Prisma Middleware for RLS**:
```typescript
// lib/prisma.ts
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Middleware to enforce row-level security
prisma.$use(async (params, next) => {
  // Get current user from context (set by auth middleware)
  const userId = (params as any).userId;
  
  if (!userId) {
    throw new Error('User not authenticated');
  }
  
  // Automatically filter queries by user_id
  if (params.model === 'User') {
    if (params.action === 'findMany' || params.action === 'findFirst') {
      params.args.where = {
        ...params.args.where,
        id: userId,
      };
    }
    
    if (params.action === 'update' || params.action === 'delete') {
      params.args.where = {
        ...params.args.where,
        id: userId,
      };
    }
  }
  
  if (params.model === 'Order') {
    if (params.action === 'findMany' || params.action === 'findFirst') {
      params.args.where = {
        ...params.args.where,
        userId: userId,
      };
    }
  }
  
  return next(params);
});

export default prisma;
```

**Transaction with Locking**:
```typescript
// Transfer funds with row locking
async function transferFunds(fromUserId: string, toUserId: string, amount: number) {
  return await prisma.$transaction(async (tx) => {
    // Lock rows for update (PostgreSQL)
    const fromUser = await tx.$queryRaw`
      SELECT * FROM "User" WHERE id = ${fromUserId} FOR UPDATE
    `;
    
    const toUser = await tx.$queryRaw`
      SELECT * FROM "User" WHERE id = ${toUserId} FOR UPDATE
    `;
    
    if (fromUser[0].balance < amount) {
      throw new Error('Insufficient funds');
    }
    
    await tx.user.update({
      where: { id: fromUserId },
      data: { balance: { decrement: amount } },
    });
    
    await tx.user.update({
      where: { id: toUserId },
      data: { balance: { increment: amount } },
    });
  }, {
    isolationLevel: 'Serializable', // Highest isolation level
  });
}
```

### SQLAlchemy (ORM patterns, transactions)

**Query Patterns**:
```python
from sqlalchemy import select, and_, or_
from sqlalchemy.orm import Session

# Pattern 1: Basic query with filter
def get_user_orders(db: Session, user_id: int):
    stmt = select(Order).where(Order.user_id == user_id)
    return db.execute(stmt).scalars().all()

# Pattern 2: Join with filter
def get_orders_with_products(db: Session, user_id: int):
    stmt = (
        select(Order, Product)
        .join(Product, Order.product_id == Product.id)
        .where(Order.user_id == user_id)
    )
    return db.execute(stmt).all()

# Pattern 3: Complex filter
def get_active_premium_users(db: Session):
    stmt = select(User).where(
        and_(
            User.subscription_status == 'active',
            User.subscription_expires > datetime.utcnow(),
            or_(
                User.plan == 'premium',
                User.plan == 'enterprise'
            )
        )
    )
    return db.execute(stmt).scalars().all()

# Pattern 4: Aggregation
from sqlalchemy import func

def get_user_order_total(db: Session, user_id: int):
    stmt = (
        select(func.sum(Order.amount))
        .where(Order.user_id == user_id)
    )
    return db.execute(stmt).scalar()
```

**Transaction Patterns**:
```python
from sqlalchemy.orm import Session
from contextlib import contextmanager

@contextmanager
def transaction(db: Session):
    """Context manager for database transactions"""
    try:
        yield db
        db.commit()
    except Exception:
        db.rollback()
        raise

# Usage
def create_order_with_items(db: Session, user_id: int, items: list):
    with transaction(db):
        # Create order
        order = Order(user_id=user_id, total=0)
        db.add(order)
        db.flush()  # Get order.id without committing
        
        # Create order items
        total = 0
        for item in items:
            order_item = OrderItem(
                order_id=order.id,
                product_id=item['product_id'],
                quantity=item['quantity'],
                price=item['price']
            )
            db.add(order_item)
            total += item['price'] * item['quantity']
        
        # Update order total
        order.total = total
        # Commit happens in context manager

# Row locking pattern
def update_product_stock(db: Session, product_id: int, quantity: int):
    with transaction(db):
        # Lock row for update
        product = db.execute(
            select(Product)
            .where(Product.id == product_id)
            .with_for_update()
        ).scalar_one()
        
        if product.stock < quantity:
            raise ValueError('Insufficient stock')
        
        product.stock -= quantity
```

## Detection Checklist

- [ ] RLS is enabled on all Supabase tables
- [ ] RLS policies use USING and WITH CHECK clauses
- [ ] Service role key is never exposed to client
- [ ] Firebase Security Rules require authentication
- [ ] Convex queries verify authentication
- [ ] No SQL injection via string interpolation
- [ ] Database connections use SSL/TLS
- [ ] Transactions use appropriate isolation levels
- [ ] SELECT FOR UPDATE used for critical operations
- [ ] Database credentials not in error messages or logs
- [ ] Indexes on frequently queried columns
- [ ] Sensitive data is encrypted
- [ ] Data retention policies implemented
- [ ] Connection pooling configured
- [ ] Database user has minimal required permissions

## Common AI Assistant Mistakes

1. **Forgetting to enable RLS** - Most common Supabase vulnerability
2. **Using service role key in client** - Complete security bypass
3. **USING (true) policies** - Allows access to all rows
4. **No WITH CHECK clause** - Allows updating to unauthorized values
5. **String interpolation in queries** - SQL injection
6. **No transaction isolation** - Race conditions
7. **Plain text sensitive data** - Data breach risk

## Remediation Priority

1. **Critical** (immediate):
   - Enable RLS on all tables
   - Remove service role key from client
   - Fix SQL injection

2. **High** (within 24 hours):
   - Add proper RLS policies
   - Fix transaction isolation
   - Encrypt sensitive data

3. **Medium** (within 1 week):
   - Add database indexes
   - Implement data retention
   - Configure connection pooling

4. **Low** (within 1 month):
   - Optimize query performance
   - Add database monitoring
   - Implement backup encryption
