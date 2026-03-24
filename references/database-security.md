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
