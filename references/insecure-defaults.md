# Insecure Defaults & Fail-Open Patterns

## Overview

Insecure defaults occur when missing, empty, or zero configuration values cause an application to run insecurely rather than fail safely. AI-generated code frequently introduces fail-open patterns — where the absence of a secret or config silently allows the app to continue with a weak fallback instead of crashing.

The key distinction: **fail-open** (exploitable) vs **fail-secure** (crashes safely).

- **Fail-open (CRITICAL):** `SECRET = env.get('KEY') or 'default'` → App runs with known weak secret
- **Fail-secure (SAFE):** `SECRET = env['KEY']` → App crashes if missing, preventing insecure operation

## Critical Patterns to Detect

### 1. Fallback Secrets

**Vulnerable patterns:**

```python
# Python - WRONG: Fallback to hardcoded secret
SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-secret-key-123')
JWT_SECRET = os.getenv('JWT_SECRET') or 'my-fallback-secret'

def create_token(user_id):
    return jwt.encode({'user_id': user_id}, SECRET_KEY, algorithm='HS256')
```

```javascript
// JavaScript - WRONG: Logical OR fallback
const DB_PASSWORD = process.env.DB_PASSWORD || 'admin123';
const JWT_SECRET = process.env.JWT_SECRET || 'fallback-secret';
```

```ruby
# Ruby - WRONG: fetch with default
SECRET_KEY_BASE = ENV.fetch('SECRET_KEY_BASE', 'fallback-secret-base')
```

**Impact**: If the environment variable is missing in production (misconfigured deployment, missing `.env` file, CI/CD pipeline), the app runs with a known, predictable secret. An attacker can forge JWTs, decrypt sessions, or authenticate as any user.

**Fix:**

```python
# Python - CORRECT: Fail-secure — crash if missing
SECRET_KEY = os.environ['SECRET_KEY']  # Raises KeyError if missing

# CORRECT: Explicit validation with clear error
SECRET_KEY = os.environ.get('SECRET_KEY')
if not SECRET_KEY:
    raise RuntimeError('SECRET_KEY environment variable is required')
```

```javascript
// JavaScript - CORRECT: Fail-secure
if (!process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET environment variable is required');
}
const JWT_SECRET = process.env.JWT_SECRET;
```

### 2. Fail-Open Authentication Flags

**Vulnerable patterns:**

```python
# Python - WRONG: Auth disabled by default
REQUIRE_AUTH = os.getenv('REQUIRE_AUTH', 'false').lower() == 'true'

@app.before_request
def check_auth():
    if not REQUIRE_AUTH:
        return  # Skip auth entirely if env var not set!
```

```javascript
// JavaScript - WRONG: SSL verification disabled by default
const VERIFY_SSL = process.env.VERIFY_SSL !== 'false';  // True unless explicitly disabled
// vs.
const VERIFY_SSL = process.env.VERIFY_SSL === 'true';   // False unless explicitly enabled — WRONG
```

**Impact**: If the environment variable is absent or misconfigured, authentication is bypassed entirely. This is especially dangerous in containerized deployments where env vars can be accidentally omitted.

**Fix:**

```python
# Python - CORRECT: Secure by default, must explicitly disable
REQUIRE_AUTH = os.getenv('REQUIRE_AUTH', 'true').lower() != 'false'

# CORRECT: Fail-secure — require explicit opt-out, not opt-in
SKIP_AUTH = os.getenv('SKIP_AUTH', 'false').lower() == 'true'
if SKIP_AUTH and os.getenv('ENVIRONMENT') == 'production':
    raise RuntimeError('Cannot skip auth in production')
```

### 3. Zero/Empty Value Bypasses

**Vulnerable patterns:**

```python
# Python - WRONG: Zero disables expiry
def verify_otp(code, lifetime=300):
    if lifetime == 0:
        return True  # Zero means "accept all"? Or "expired immediately"?
    return check_otp_within_window(code, lifetime)

# WRONG: Empty string bypasses check
def verify_signature(sig, data, key):
    if not key:
        return True  # No key = skip verification!
```

```javascript
// JavaScript - WRONG: Zero max_attempts disables lockout
function checkLoginAttempts(userId, maxAttempts = 5) {
  if (maxAttempts === 0) return true;  // 0 = unlimited attempts
  return getAttempts(userId) < maxAttempts;
}
```

**Impact**: Attackers or misconfigured deployments can pass `0`, `""`, or `null` to disable security controls entirely.

**Fix:**

```python
# Python - CORRECT: Validate and reject insecure values
def verify_otp(code, lifetime=300):
    if lifetime <= 0:
        raise ValueError('OTP lifetime must be positive')
    return check_otp_within_window(code, lifetime)

def verify_signature(sig, data, key):
    if not key:
        raise ValueError('Signing key is required')
    return hmac.compare_digest(compute_sig(data, key), sig)
```

### 4. Hardcoded Default Credentials

**Vulnerable patterns:**

```python
# Python - WRONG: Default admin account with known credentials
def bootstrap_admin():
    if not User.query.filter_by(role='admin').first():
        admin = User(
            username='admin',
            password=hash_password('admin123'),
            role='admin'
        )
        db.session.add(admin)
        db.session.commit()
```

```yaml
# docker-compose.yml - WRONG: Default credentials
services:
  db:
    image: postgres
    environment:
      POSTGRES_PASSWORD: postgres  # Default, widely known
      POSTGRES_USER: admin
```

**Impact**: Default credentials are the first thing attackers try. Any deployment that doesn't change them is immediately compromised.

**Fix:**

```python
# Python - CORRECT: Require credentials from environment
def bootstrap_admin():
    username = os.environ['ADMIN_USERNAME']
    password = os.environ['ADMIN_PASSWORD']
    if len(password) < 16:
        raise ValueError('Admin password must be at least 16 characters')
    if not User.query.filter_by(username=username).first():
        admin = User(username=username, password=hash_password(password), role='admin')
        db.session.add(admin)
```

### 5. Debug/Development Modes in Production

**Vulnerable patterns:**

```python
# Python - WRONG: Debug enabled by default
DEBUG = os.getenv('DEBUG', 'true').lower() == 'true'
app.run(debug=DEBUG)

# WRONG: Development mode assumed
if os.getenv('ENVIRONMENT') != 'production':
    app.config['TESTING'] = True
    app.config['WTF_CSRF_ENABLED'] = False
```

**Impact**: Debug mode exposes interactive debuggers, stack traces, and internal state. Disabling CSRF in non-production environments that accidentally reach production creates CSRF vulnerabilities.

**Fix:**

```python
# Python - CORRECT: Secure by default
DEBUG = os.getenv('DEBUG', 'false').lower() == 'true'
ENVIRONMENT = os.getenv('ENVIRONMENT', 'production')  # Default to most restrictive

if ENVIRONMENT == 'production' and DEBUG:
    raise RuntimeError('DEBUG must not be enabled in production')
```

### 6. Insecure Configuration Combinations

**Vulnerable patterns:**

```yaml
# WRONG: Auth required but health check bypasses everything
auth_required: true
bypass_auth_for_health_checks: true
health_check_path: "/"  # Entire app accessible via health check path

# WRONG: Typo silently accepted
verify_ssl: fasle  # Typo — is this truthy or falsy?
```

```python
# Python - WRONG: Constructor accepts insecure values without validation
class TokenVerifier:
    def __init__(self, algorithm='HS256', lifetime=3600):
        self.algorithm = algorithm  # Accepts 'none', 'md5', anything
        self.lifetime = lifetime    # Accepts 0, -1, no validation
```

**Fix:**

```python
# Python - CORRECT: Validate all security-relevant config at construction
ALLOWED_ALGORITHMS = {'HS256', 'HS384', 'HS512', 'RS256', 'RS384', 'RS512'}

class TokenVerifier:
    def __init__(self, algorithm='HS256', lifetime=3600):
        if algorithm not in ALLOWED_ALGORITHMS:
            raise ValueError(f'Algorithm must be one of: {ALLOWED_ALGORITHMS}')
        if lifetime <= 0:
            raise ValueError('Token lifetime must be positive')
        self.algorithm = algorithm
        self.lifetime = lifetime
```

## Detection Checklist

When auditing for insecure defaults:

- [ ] Search for `os.getenv(..., 'default')` and `os.environ.get(..., 'default')` — check if default is a secret or security-relevant value
- [ ] Search for `|| 'default'`, `?? 'default'`, `or 'default'` in JavaScript/Python — same concern
- [ ] Check boolean flags: does the default enable or disable security?
- [ ] Check numeric parameters: what happens with `0`, `-1`, or very large values?
- [ ] Check string parameters: what happens with `""` or `null`?
- [ ] Verify debug/development modes default to off, not on
- [ ] Check for hardcoded default credentials in bootstrap/seed scripts
- [ ] Verify configuration validation rejects dangerous combinations

## Rationalizations to Reject

| Rationalization | Why It's Wrong |
|---|---|
| "It's just a development default" | If it reaches production code, it's a finding |
| "The production config overrides it" | Verify prod config exists; code-level vulnerability remains if not |
| "This would never run without proper config" | Prove it with code trace; many apps fail silently |
| "It's behind authentication" | Defense in depth; compromised session still exploits weak defaults |
| "We'll fix it before release" | Document now; "later" rarely comes |

## Quick Fix Patterns

### Pattern 1: Fallback Secret → Fail-Secure

```diff
- SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-secret-key-123')
+ SECRET_KEY = os.environ['SECRET_KEY']
```

```diff
- const JWT_SECRET = process.env.JWT_SECRET || 'fallback';
+ if (!process.env.JWT_SECRET) throw new Error('JWT_SECRET required');
+ const JWT_SECRET = process.env.JWT_SECRET;
```

### Pattern 2: Fail-Open Auth Flag → Secure Default

```diff
- REQUIRE_AUTH = os.getenv('REQUIRE_AUTH', 'false').lower() == 'true'
+ REQUIRE_AUTH = os.getenv('REQUIRE_AUTH', 'true').lower() != 'false'
```

### Pattern 3: Zero-Value Bypass → Validate Inputs

```diff
  def verify_otp(code, lifetime=300):
+     if lifetime <= 0:
+         raise ValueError('OTP lifetime must be positive')
      return check_otp_within_window(code, lifetime)
```

### Pattern 4: Unvalidated Constructor → Validate at Construction

```diff
  class TokenVerifier:
      def __init__(self, algorithm='HS256', lifetime=3600):
+         if algorithm not in {'HS256', 'RS256', 'RS384', 'RS512'}:
+             raise ValueError(f'Unsupported algorithm: {algorithm}')
+         if lifetime <= 0:
+             raise ValueError('Lifetime must be positive')
          self.algorithm = algorithm
          self.lifetime = lifetime
```
