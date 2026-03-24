# API & Library Sharp Edges

## Overview

Sharp edges are APIs, configurations, and interfaces where the easy path leads to insecurity. The core principle: **secure usage should be the path of least resistance** (the "pit of success"). If developers must understand cryptography deeply, read documentation carefully, or remember special rules to avoid vulnerabilities, the API has failed — and AI-generated code will almost always take the insecure path.

This reference covers patterns where the API design itself enables security mistakes, distinct from implementation bugs.

## Critical Patterns to Detect

### 1. Algorithm/Mode Selection Footguns

APIs that let developers choose cryptographic algorithms invite choosing wrong ones.

**The JWT `alg: none` pattern:**

```python
# Python - WRONG: Accepting any algorithm including 'none'
def verify_token(token):
    payload = jwt.decode(token, JWT_SECRET, algorithms=['HS256', 'RS256', 'none'])
    return payload

# WRONG: Not specifying algorithms at all
def verify_token(token):
    payload = jwt.decode(token, JWT_SECRET)  # Library may accept 'none'
    return payload
```

**Impact**: Attacker modifies the JWT header to `"alg": "none"`, removes the signature, and the library accepts it as valid. Complete authentication bypass.

**The RS256 → HS256 confusion attack:**

```python
# WRONG: Accepting both asymmetric and symmetric algorithms
def verify_token(token):
    # If server uses RS256, attacker can:
    # 1. Get the public key (often publicly available)
    # 2. Sign a token with HS256 using the PUBLIC key as the HMAC secret
    # 3. Server verifies with HS256 using the same public key — succeeds!
    payload = jwt.decode(token, public_key, algorithms=['HS256', 'RS256'])
```

**Fix:**

```python
# Python - CORRECT: Specify exactly one algorithm
def verify_token(token):
    payload = jwt.decode(
        token,
        JWT_SECRET,
        algorithms=['HS256']  # Exactly one, never 'none', never mixed asymmetric+symmetric
    )
    return payload
```

**Detection patterns to search for:**
- `algorithms=['HS256', 'RS256']` — mixed algorithm lists
- `algorithms=['none']` or `'none'` in algorithm lists
- `jwt.decode(token, key)` without explicit `algorithms` parameter
- `verify=False` or `verify_signature=False`

### 2. Dangerous Defaults and Zero-Value Bypasses

Security parameters where zero, empty, or null disables protection.

**Vulnerable patterns:**

```python
# Python - WRONG: Zero disables expiry check
def verify_token(token, max_age=3600):
    if max_age == 0:
        return True  # Intended as "no expiry" but accepts all tokens

# WRONG: Empty key skips verification
def verify_hmac(data, signature, key=''):
    if not key:
        return True  # No key configured = skip check
    return hmac.compare_digest(compute_hmac(data, key), signature)
```

```javascript
// JavaScript - WRONG: Negative timeout means "never expire"
function createSession(userId, timeout = 3600) {
  const expiry = timeout < 0 ? null : Date.now() + timeout * 1000;
  return { userId, expiry };  // null expiry = session never expires
}
```

**Fix:**

```python
# Python - CORRECT: Reject insecure values explicitly
def verify_token(token, max_age=3600):
    if max_age <= 0:
        raise ValueError('max_age must be positive')
    # ...

def verify_hmac(data, signature, key):
    if not key:
        raise ValueError('HMAC key is required')
    return hmac.compare_digest(compute_hmac(data, key), signature)
```

### 3. Primitive vs. Semantic APIs (Type Confusion)

APIs that use the same type for different security concepts allow silent parameter swapping.

**Vulnerable patterns:**

```python
# Python - WRONG: All parameters are bytes — easy to swap
def encrypt(plaintext: bytes, key: bytes, nonce: bytes) -> bytes:
    ...

# Caller can accidentally swap key and nonce — same type, no error
ciphertext = encrypt(data, nonce, key)  # Silently wrong
```

```go
// Go - WRONG: Timing-unsafe comparison looks identical to safe
if token == expected { }                    // BAD: timing attack
if hmac.Equal(token, expected) { }          // Good: constant-time
// Both look the same to a developer copying code
```

```javascript
// JavaScript - WRONG: Signing and verification keys are both strings
function signJWT(payload, key) { ... }
function verifyJWT(token, key) { ... }

// Developer accidentally uses signing key for verification in asymmetric setup
const token = signJWT(payload, privateKey);
const valid = verifyJWT(token, privateKey);  // Should use publicKey!
```

**Fix:**

```python
# Python - CORRECT: Use typed wrappers to prevent confusion
from dataclasses import dataclass

@dataclass(frozen=True)
class EncryptionKey:
    value: bytes

@dataclass(frozen=True)
class Nonce:
    value: bytes

def encrypt(plaintext: bytes, key: EncryptionKey, nonce: Nonce) -> bytes:
    ...

# Now swapping is a type error, not a silent bug
encrypt(data, Nonce(n), EncryptionKey(k))  # TypeError at call site
```

### 4. Configuration Cliffs

One wrong setting creates catastrophic failure with no warning.

**Vulnerable patterns:**

```yaml
# WRONG: Typo silently accepted as truthy
verify_ssl: fasle   # Typo — Python reads this as the string "fasle" which is truthy!

# WRONG: Magic value disables security
session_timeout: -1  # Does this mean "never expire" or "error"?

# WRONG: Dangerous combination accepted silently
auth_required: true
bypass_auth_for_health_checks: true
health_check_path: "/"  # Entire app accessible via health check
```

```python
# Python - WRONG: Constructor accepts any value without validation
class CryptoConfig:
    def __init__(
        self,
        hash_algo: str = 'sha256',   # Accepts 'md5', 'sha1', anything
        key_size: int = 256,          # Accepts 0, 1, negative values
        iterations: int = 100000,     # Accepts 1 (trivially brute-forceable)
    ):
        self.hash_algo = hash_algo
        self.key_size = key_size
        self.iterations = iterations
```

**Fix:**

```python
# Python - CORRECT: Validate all security-relevant config at construction
ALLOWED_HASH_ALGOS = {'sha256', 'sha384', 'sha512'}
MIN_KEY_SIZE = 128
MIN_ITERATIONS = 10000

class CryptoConfig:
    def __init__(
        self,
        hash_algo: str = 'sha256',
        key_size: int = 256,
        iterations: int = 100000,
    ):
        if hash_algo not in ALLOWED_HASH_ALGOS:
            raise ValueError(f'hash_algo must be one of {ALLOWED_HASH_ALGOS}')
        if key_size < MIN_KEY_SIZE:
            raise ValueError(f'key_size must be at least {MIN_KEY_SIZE}')
        if iterations < MIN_ITERATIONS:
            raise ValueError(f'iterations must be at least {MIN_ITERATIONS}')
        self.hash_algo = hash_algo
        self.key_size = key_size
        self.iterations = iterations
```

### 5. Silent Security Failures

Errors that don't surface, or "success" that masks failure.

**Vulnerable patterns:**

```python
# Python - WRONG: Returns False instead of raising on failure
def verify_signature(data, sig, key):
    try:
        return hmac.compare_digest(compute_sig(data, key), sig)
    except Exception:
        return False  # Swallows errors — malformed input "fails" silently

# WRONG: Return value ignored by callers
signature.verify(data, sig)  # Raises on failure — correct
crypto.verify(data, sig)     # Returns False on failure — easy to ignore
result = crypto.verify(data, sig)
# Developer forgets: if result: ...
```

```javascript
// JavaScript - WRONG: Async verification with swallowed error
async function verifyToken(token) {
  try {
    return await jwt.verify(token, secret);
  } catch (e) {
    return null;  // Caller may not check for null
  }
}

// Caller:
const user = await verifyToken(token);
doSomethingWith(user.id);  // TypeError if null, but no security check
```

**Fix:**

```python
# Python - CORRECT: Raise on failure, never return False for security checks
def verify_signature(data, sig, key):
    expected = compute_sig(data, key)
    if not hmac.compare_digest(expected, sig):
        raise SecurityError('Signature verification failed')
    return True  # Explicit success

# CORRECT: Use exceptions so callers can't ignore failures
```

### 6. Stringly-Typed Security Values

Security-critical values as plain strings enable injection and confusion.

**Vulnerable patterns:**

```python
# Python - WRONG: Permissions as comma-separated strings
user_permissions = "read,write"
user_permissions += ",admin"  # Trivially escalated

def has_permission(user_permissions: str, required: str) -> bool:
    return required in user_permissions.split(',')

# Attacker sends: required = "rea"
# "rea" in ["read", "write"] → False, but:
# "rea" in "read,write" → True if using substring check!
```

```javascript
// JavaScript - WRONG: Roles as arbitrary strings
function checkRole(userRole, requiredRole) {
  return userRole === requiredRole;  // String comparison, easy to spoof
}

// No validation that userRole is a valid role at all
```

**Fix:**

```python
# Python - CORRECT: Use enums for security-critical values
from enum import Enum

class Permission(Enum):
    READ = 'read'
    WRITE = 'write'
    ADMIN = 'admin'

def has_permission(user_permissions: set[Permission], required: Permission) -> bool:
    return required in user_permissions  # Type-safe set membership

# Escalation requires explicit enum value, not string manipulation
```

## Detection Checklist

When auditing for sharp edges:

- [ ] JWT: `algorithms` parameter specifies exactly one algorithm, never includes `'none'`, never mixes asymmetric and symmetric
- [ ] Crypto functions: check what happens with `key=""`, `key=None`, `iterations=0`, `key_size=0`
- [ ] Config constructors: are security-relevant parameters validated, or just defaulted?
- [ ] Comparison functions: are timing-safe comparisons used for secrets? (`hmac.compare_digest`, `secrets.compare_digest`)
- [ ] Return values: do security verification functions raise on failure, or return False/None?
- [ ] Permissions/roles: are they typed (enums, sets) or stringly-typed?
- [ ] Boolean config flags: does `False`/`0`/`""` disable security? Is that the default?
- [ ] SSL/TLS: is certificate verification on by default? Can it be disabled via config?

## Quick Fix Patterns

### Pattern 1: Mixed Algorithm List → Single Algorithm

```diff
- payload = jwt.decode(token, secret, algorithms=['HS256', 'RS256', 'none'])
+ payload = jwt.decode(token, secret, algorithms=['HS256'])
```

### Pattern 2: Zero/Empty Bypass → Validate Inputs

```diff
  def verify_hmac(data, sig, key):
+     if not key:
+         raise ValueError('HMAC key is required')
      return hmac.compare_digest(compute_hmac(data, key), sig)
```

### Pattern 3: Unvalidated Constructor → Validate at Construction

```diff
  class CryptoConfig:
      def __init__(self, algorithm='sha256', iterations=100000):
+         if algorithm not in {'sha256', 'sha384', 'sha512'}:
+             raise ValueError(f'Unsupported algorithm: {algorithm}')
+         if iterations < 10000:
+             raise ValueError('iterations must be at least 10000')
          self.algorithm = algorithm
          self.iterations = iterations
```

### Pattern 4: Silent Failure → Raise on Failure

```diff
  def verify_signature(data, sig, key):
-     try:
-         return hmac.compare_digest(compute_sig(data, key), sig)
-     except Exception:
-         return False
+     expected = compute_sig(data, key)
+     if not hmac.compare_digest(expected, sig):
+         raise SecurityError('Signature verification failed')
+     return True
```

### Pattern 5: Stringly-Typed Permissions → Enums

```diff
- user_permissions = "read,write"
- user_permissions += ",admin"
+ from enum import Enum
+ class Permission(Enum):
+     READ = 'read'
+     WRITE = 'write'
+     ADMIN = 'admin'
+ user_permissions: set[Permission] = {Permission.READ, Permission.WRITE}
```
