# Vibe Security Enhanced - Quick Reference Card

## Installation (One Command)

```bash
# Windows
INSTALL.bat

# Mac/Linux
chmod +x INSTALL.sh && ./INSTALL.sh
```

## Activation

**Automatic:** Triggers on security keywords, code reviews, auth/payment/database work

**Manual:**
- Kiro/Claude: "Run a security audit"
- Claude Code: `/vibe-security-enhanced`

## Top 10 Vulnerabilities Detected

| # | Vulnerability | Impact | Fix |
|---|---------------|--------|-----|
| 1 | Hardcoded secrets | Credential theft | Use environment variables |
| 2 | SQL injection | Database compromise | Use parameterized queries |
| 3 | JWT without verification | Auth bypass | Verify signature with jwt.verify() |
| 4 | Disabled RLS | Data breach | Enable RLS + proper policies |
| 5 | Float for money | Financial errors | Use Decimal type |
| 6 | Client-side prices | Price manipulation | Look up prices server-side |
| 7 | Race conditions | Double-spending | Use SELECT FOR UPDATE |
| 8 | Weak password hashing | Password cracking | Use bcrypt or Argon2 |
| 9 | Command injection | System compromise | Use list args, no shell=True |
| 10 | Missing auth checks | Unauthorized access | Add @require_auth decorator |

## Quick Checks

### Secrets
```bash
# Bad
API_KEY = "sk-proj-abc123..."

# Good
API_KEY = os.environ['API_KEY']
```

### SQL Injection
```python
# Bad
query = f"SELECT * FROM users WHERE id = '{user_id}'"

# Good
query = "SELECT * FROM users WHERE id = ?"
db.execute(query, (user_id,))
```

### JWT Verification
```python
# Bad
payload = jwt.decode(token, options={"verify_signature": False})

# Good
payload = jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
```

### Money Calculations
```python
# Bad
total = 19.99 * 3  # Float arithmetic

# Good
total = Decimal('19.99') * 3  # Exact
```

### Race Conditions
```python
# Bad
if user.balance >= amount:
    user.balance -= amount  # Race condition!

# Good
with db.begin():
    user = db.query(User).with_for_update().first()
    if user.balance >= amount:
        user.balance -= amount
```

## Severity Levels

- **Critical:** Immediate exploitation, severe impact (fix now)
- **High:** Likely exploitation, significant impact (fix within 24h)
- **Medium:** Possible exploitation, moderate impact (fix within 1 week)
- **Low:** Difficult to exploit, minimal impact (fix next sprint)

## Common Patterns

### Authentication
```python
@app.route('/api/data')
@require_auth  # Always require auth
def get_data():
    # Use request.user_id from token, not from request
    return get_user_data(request.user_id)
```

### Authorization
```python
# Always verify ownership
order = db.get_order(order_id)
if order.user_id != request.user_id:
    abort(403)
```

### Input Validation
```python
# Validate everything
if not isinstance(amount, Decimal) or amount <= 0:
    raise ValueError("Invalid amount")
```

## File Structure

```
vibe-security-enhanced/
├── skill.md                    # Main skill
└── references/
    ├── secrets-and-env.md      # ✅ Complete
    ├── authentication.md       # ✅ Complete
    ├── input-validation.md     # ✅ Complete
    ├── database-security.md    # ✅ Complete
    └── financial-security.md   # ✅ Complete
```

## Supported Technologies

**Languages:** Python, JavaScript, TypeScript, SQL  
**Frameworks:** Flask, Django, FastAPI, React, Next.js, Vue, Express  
**Databases:** PostgreSQL, MySQL, MongoDB, Supabase, Firebase, Convex  
**Payment:** Stripe, PayPal, Coinbase Commerce  
**ML/AI:** TensorFlow, PyTorch, OpenAI, Anthropic  
**Trading:** CCXT, Binance, Coinbase, Kraken APIs  

## Getting Help

1. **Read README.md** - Full documentation
2. **Check EXPORT_SUMMARY.md** - Package details
3. **Review reference files** - Detailed patterns
4. **Original project:** https://github.com/raroque/vibe-security-skill

## Quick Tips

✅ Run audits before major releases  
✅ Use during code reviews  
✅ Let it guide secure code generation  
✅ Fix critical issues immediately  
✅ Customize for your project  
✅ Keep reference files updated  

❌ Don't ignore critical findings  
❌ Don't skip authentication checks  
❌ Don't trust client-side data  
❌ Don't use float for money  
❌ Don't hardcode secrets  

## One-Liner Fixes

```python
# Secrets
API_KEY = os.environ['API_KEY']

# SQL
db.execute("SELECT * FROM users WHERE id = ?", (user_id,))

# JWT
jwt.decode(token, SECRET, algorithms=['HS256'])

# Money
Decimal('19.99')

# Auth
@require_auth

# Validation
if not isinstance(value, expected_type): raise ValueError()

# Race condition
with db.begin(): user = query.with_for_update().first()
```

---

**Remember:** Security is not optional. Audit early, audit often!
