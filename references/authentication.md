# Authentication & Authorization Security

## Overview

Authentication (verifying who you are) and authorization (verifying what you can do) are critical security controls. AI-generated code frequently introduces authentication bypasses, weak password handling, insecure session management, and broken access control.

## Critical Patterns to Detect

### 1. JWT Verification Failures

**Vulnerable patterns:**

```python
# Python - WRONG: Decoding without verification
import jwt
import json
import base64

def get_user_from_token(token):
    # This only decodes, doesn't verify signature!
    payload = jwt.decode(token, options={"verify_signature": False})
    return payload['user_id']

# WRONG: Manual base64 decoding
def get_user_id(token):
    parts = token.split('.')
    payload = json.loads(base64.b64decode(parts[1]))
    return payload['user_id']  # No signature verification!
```

```javascript
// JavaScript - WRONG: jwt.decode() doesn't verify
const jwt = require('jsonwebtoken');

function getUserFromToken(token) {
  const payload = jwt.decode(token);  // No verification!
  return payload.userId;
}
```

**Impact**: An attacker can create their own JWT with any user_id, role, or permissions and the application will accept it. This allows complete authentication bypass and privilege escalation.

**Proof of concept**:
```python
# Attacker creates fake JWT
import jwt

fake_token = jwt.encode(
    {'user_id': 1, 'role': 'admin', 'exp': 9999999999},
    'wrong-secret',  # Doesn't matter, not verified!
    algorithm='HS256'
)
# Application accepts this token and grants admin access
```

**Fix:**

```python
# Python - CORRECT: Verify signature
import jwt
import os
from datetime import datetime, timedelta

JWT_SECRET = os.environ['JWT_SECRET']
JWT_ALGORITHM = 'HS256'

def create_token(user_id, role):
    payload = {
        'user_id': user_id,
        'role': role,
        'exp': datetime.utcnow() + timedelta(hours=24),
        'iat': datetime.utcnow(),
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)

def verify_token(token):
    try:
        payload = jwt.decode(
            token,
            JWT_SECRET,
            algorithms=[JWT_ALGORITHM],  # Specify allowed algorithms
            options={
                'verify_signature': True,
                'verify_exp': True,
                'verify_iat': True,
                'require': ['exp', 'iat', 'user_id']
            }
        )
        return payload
    except jwt.ExpiredSignatureError:
        raise AuthenticationError("Token has expired")
    except jwt.InvalidTokenError:
        raise AuthenticationError("Invalid token")

def get_user_from_token(token):
    payload = verify_token(token)
    return payload['user_id']
```

```javascript
// JavaScript - CORRECT: Verify signature
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_ALGORITHM = 'HS256';

function createToken(userId, role) {
  return jwt.sign(
    { userId, role },
    JWT_SECRET,
    { algorithm: JWT_ALGORITHM, expiresIn: '24h' }
  );
}

function verifyToken(token) {
  try {
    return jwt.verify(token, JWT_SECRET, { algorithms: [JWT_ALGORITHM] });
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      throw new Error('Token has expired');
    }
    throw new Error('Invalid token');
  }
}

function getUserFromToken(token) {
  const payload = verifyToken(token);
  return payload.userId;
}
```

### 2. Algorithm Confusion Attack

**Vulnerable patterns:**

```python
# Python - WRONG: Accepting any algorithm
def verify_token(token):
    payload = jwt.decode(token, JWT_SECRET, algorithms=['HS256', 'RS256', 'none'])
    return payload
```

**Impact**: Attacker can change the algorithm to 'none' and bypass signature verification entirely.

**Fix:**

```python
# Python - CORRECT: Specify exact algorithm
def verify_token(token):
    payload = jwt.decode(
        token,
        JWT_SECRET,
        algorithms=['HS256']  # Only allow expected algorithm
    )
    return payload
```

### 3. Weak Password Storage

**Vulnerable patterns:**

```python
# Python - WRONG: Plain text passwords
def create_user(username, password):
    db.execute("INSERT INTO users (username, password) VALUES (?, ?)", 
               (username, password))

# WRONG: Weak hashing (MD5, SHA1, SHA256)
import hashlib

def create_user(username, password):
    password_hash = hashlib.md5(password.encode()).hexdigest()
    db.execute("INSERT INTO users (username, password_hash) VALUES (?, ?)",
               (username, password_hash))

# WRONG: Hashing without salt
def create_user(username, password):
    password_hash = hashlib.sha256(password.encode()).hexdigest()
    db.execute("INSERT INTO users (username, password_hash) VALUES (?, ?)",
               (username, password_hash))
```

**Impact**: 
- Plain text: Database breach exposes all passwords
- MD5/SHA1/SHA256: Fast hashing allows rainbow table and brute force attacks
- No salt: Identical passwords have identical hashes, enabling rainbow tables

**Fix:**

```python
# Python - CORRECT: Use bcrypt or Argon2
import bcrypt

def create_user(username, password):
    # bcrypt automatically generates salt and uses slow hashing
    password_hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12))
    db.execute("INSERT INTO users (username, password_hash) VALUES (?, ?)",
               (username, password_hash))

def verify_password(username, password):
    user = db.execute("SELECT password_hash FROM users WHERE username = ?", 
                      (username,)).fetchone()
    if not user:
        # Prevent timing attacks - still hash even if user doesn't exist
        bcrypt.hashpw(password.encode(), bcrypt.gensalt())
        return False
    
    return bcrypt.checkpw(password.encode(), user['password_hash'])

# Or use Argon2 (recommended for new projects)
from argon2 import PasswordHasher

ph = PasswordHasher()

def create_user(username, password):
    password_hash = ph.hash(password)
    db.execute("INSERT INTO users (username, password_hash) VALUES (?, ?)",
               (username, password_hash))

def verify_password(username, password):
    user = db.execute("SELECT password_hash FROM users WHERE username = ?",
                      (username,)).fetchone()
    if not user:
        return False
    
    try:
        ph.verify(user['password_hash'], password)
        # Check if rehashing is needed (parameters changed)
        if ph.check_needs_rehash(user['password_hash']):
            new_hash = ph.hash(password)
            db.execute("UPDATE users SET password_hash = ? WHERE username = ?",
                      (new_hash, username))
        return True
    except:
        return False
```

### 4. Insecure Password Reset

**Vulnerable patterns:**

```python
# Python - WRONG: Predictable reset tokens
import hashlib
from datetime import datetime

def generate_reset_token(user_id):
    # Predictable token based on user_id and timestamp
    token = hashlib.md5(f"{user_id}{datetime.now()}".encode()).hexdigest()
    return token

# WRONG: No expiration
def reset_password(token, new_password):
    user = db.execute("SELECT * FROM users WHERE reset_token = ?", (token,)).fetchone()
    if user:
        update_password(user['id'], new_password)

# WRONG: Token reuse allowed
def reset_password(token, new_password):
    user = db.execute("SELECT * FROM users WHERE reset_token = ?", (token,)).fetchone()
    if user:
        update_password(user['id'], new_password)
        # Token not invalidated - can be reused!
```

**Impact**: 
- Predictable tokens can be guessed
- No expiration allows indefinite token validity
- Token reuse allows multiple password resets

**Fix:**

```python
# Python - CORRECT: Secure password reset
import secrets
from datetime import datetime, timedelta

def generate_reset_token(user_id):
    # Cryptographically secure random token
    token = secrets.token_urlsafe(32)
    expires_at = datetime.utcnow() + timedelta(hours=1)
    
    db.execute("""
        UPDATE users 
        SET reset_token = ?, reset_token_expires = ?
        WHERE id = ?
    """, (token, expires_at, user_id))
    
    return token

def reset_password(token, new_password):
    user = db.execute("""
        SELECT * FROM users 
        WHERE reset_token = ? 
        AND reset_token_expires > ?
    """, (token, datetime.utcnow())).fetchone()
    
    if not user:
        raise ValueError("Invalid or expired reset token")
    
    # Update password
    password_hash = bcrypt.hashpw(new_password.encode(), bcrypt.gensalt())
    
    # Invalidate token after use
    db.execute("""
        UPDATE users 
        SET password_hash = ?, reset_token = NULL, reset_token_expires = NULL
        WHERE id = ?
    """, (password_hash, user['id']))
    
    # Invalidate all existing sessions
    db.execute("DELETE FROM sessions WHERE user_id = ?", (user['id'],))
```

### 5. Missing Authentication on Endpoints

**Vulnerable patterns:**

```python
# Flask - WRONG: No authentication required
@app.route('/api/user/profile', methods=['GET'])
def get_profile():
    user_id = request.args.get('user_id')
    user = db.get_user(user_id)
    return jsonify(user)

# WRONG: Authentication only in frontend
@app.route('/api/admin/users', methods=['GET'])
def get_all_users():
    # Frontend checks if user is admin, but backend doesn't
    users = db.get_all_users()
    return jsonify(users)
```

**Impact**: Anyone can access protected endpoints by calling the API directly, bypassing frontend checks.

**Fix:**

```python
# Flask - CORRECT: Server-side authentication required
from functools import wraps
from flask import request, jsonify

def require_auth(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        if not token:
            return jsonify({'error': 'No token provided'}), 401
        
        try:
            payload = verify_token(token)
            request.user_id = payload['user_id']
            request.user_role = payload['role']
        except Exception as e:
            return jsonify({'error': 'Invalid token'}), 401
        
        return f(*args, **kwargs)
    return decorated_function

def require_role(role):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if request.user_role != role:
                return jsonify({'error': 'Insufficient permissions'}), 403
            return f(*args, **kwargs)
        return decorated_function
    return decorator

@app.route('/api/user/profile', methods=['GET'])
@require_auth
def get_profile():
    # User can only access their own profile
    user = db.get_user(request.user_id)
    return jsonify(user)

@app.route('/api/admin/users', methods=['GET'])
@require_auth
@require_role('admin')
def get_all_users():
    users = db.get_all_users()
    return jsonify(users)
```

### 6. Insecure Direct Object References (IDOR)

**Vulnerable patterns:**

```python
# Python - WRONG: No authorization check
@app.route('/api/orders/<order_id>', methods=['GET'])
@require_auth
def get_order(order_id):
    # User is authenticated but not authorized to view this specific order
    order = db.get_order(order_id)
    return jsonify(order)

# WRONG: Client-provided user_id
@app.route('/api/user/balance', methods=['GET'])
@require_auth
def get_balance():
    user_id = request.args.get('user_id')  # Attacker can change this!
    balance = db.get_balance(user_id)
    return jsonify({'balance': balance})
```

**Impact**: Authenticated users can access other users' data by changing IDs in requests.

**Fix:**

```python
# Python - CORRECT: Verify ownership
@app.route('/api/orders/<order_id>', methods=['GET'])
@require_auth
def get_order(order_id):
    order = db.get_order(order_id)
    if not order:
        return jsonify({'error': 'Order not found'}), 404
    
    # Verify user owns this order
    if order['user_id'] != request.user_id:
        return jsonify({'error': 'Unauthorized'}), 403
    
    return jsonify(order)

# CORRECT: Use authenticated user_id from token
@app.route('/api/user/balance', methods=['GET'])
@require_auth
def get_balance():
    # Use user_id from verified token, not from request
    balance = db.get_balance(request.user_id)
    return jsonify({'balance': balance})
```

### 7. Session Management Issues

**Vulnerable patterns:**

```python
# Python - WRONG: Predictable session IDs
import hashlib
from datetime import datetime

def create_session(user_id):
    session_id = hashlib.md5(f"{user_id}{datetime.now()}".encode()).hexdigest()
    sessions[session_id] = user_id
    return session_id

# WRONG: No session expiration
sessions = {}  # Never cleaned up

# WRONG: Session fixation vulnerability
@app.route('/login', methods=['POST'])
def login():
    username = request.form['username']
    password = request.form['password']
    
    if verify_password(username, password):
        # Reusing existing session ID - vulnerable to fixation
        session['user_id'] = get_user_id(username)
        return redirect('/dashboard')
```

**Impact**:
- Predictable session IDs can be guessed
- No expiration allows indefinite session validity
- Session fixation allows attackers to hijack sessions

**Fix:**

```python
# Python - CORRECT: Secure session management
import secrets
from datetime import datetime, timedelta

def create_session(user_id):
    # Cryptographically secure random session ID
    session_id = secrets.token_urlsafe(32)
    expires_at = datetime.utcnow() + timedelta(hours=24)
    
    db.execute("""
        INSERT INTO sessions (session_id, user_id, expires_at, created_at)
        VALUES (?, ?, ?, ?)
    """, (session_id, user_id, expires_at, datetime.utcnow()))
    
    return session_id

def verify_session(session_id):
    session = db.execute("""
        SELECT * FROM sessions 
        WHERE session_id = ? AND expires_at > ?
    """, (session_id, datetime.utcnow())).fetchone()
    
    if not session:
        return None
    
    # Update last activity
    db.execute("""
        UPDATE sessions 
        SET last_activity = ?
        WHERE session_id = ?
    """, (datetime.utcnow(), session_id))
    
    return session['user_id']

def invalidate_session(session_id):
    db.execute("DELETE FROM sessions WHERE session_id = ?", (session_id,))

@app.route('/login', methods=['POST'])
def login():
    username = request.form['username']
    password = request.form['password']
    
    if verify_password(username, password):
        user_id = get_user_id(username)
        
        # Regenerate session ID after login (prevent fixation)
        old_session_id = session.get('session_id')
        if old_session_id:
            invalidate_session(old_session_id)
        
        session_id = create_session(user_id)
        session['session_id'] = session_id
        
        return redirect('/dashboard')
    
    return jsonify({'error': 'Invalid credentials'}), 401

@app.route('/logout', methods=['POST'])
def logout():
    session_id = session.get('session_id')
    if session_id:
        invalidate_session(session_id)
    session.clear()
    return redirect('/login')

# Cleanup expired sessions periodically
def cleanup_expired_sessions():
    db.execute("DELETE FROM sessions WHERE expires_at < ?", (datetime.utcnow(),))
```

### 8. OAuth/Social Login Vulnerabilities

**Vulnerable patterns:**

```python
# Python - WRONG: No state parameter (CSRF vulnerability)
@app.route('/auth/google')
def google_auth():
    redirect_uri = url_for('google_callback', _external=True)
    return redirect(f'https://accounts.google.com/o/oauth2/v2/auth?client_id={CLIENT_ID}&redirect_uri={redirect_uri}&response_type=code&scope=email profile')

# WRONG: Not verifying redirect_uri
@app.route('/auth/google/callback')
def google_callback():
    code = request.args.get('code')
    # Exchange code for token without validating redirect_uri
    token = exchange_code_for_token(code)
    user = get_user_from_token(token)
    session['user_id'] = user['id']
    return redirect('/')
```

**Impact**: CSRF attacks can trick users into authenticating with attacker's account.

**Fix:**

```python
# Python - CORRECT: Secure OAuth flow
import secrets

@app.route('/auth/google')
def google_auth():
    # Generate and store state parameter
    state = secrets.token_urlsafe(32)
    session['oauth_state'] = state
    
    redirect_uri = url_for('google_callback', _external=True)
    params = {
        'client_id': CLIENT_ID,
        'redirect_uri': redirect_uri,
        'response_type': 'code',
        'scope': 'email profile',
        'state': state,  # CSRF protection
    }
    
    auth_url = 'https://accounts.google.com/o/oauth2/v2/auth?' + urlencode(params)
    return redirect(auth_url)

@app.route('/auth/google/callback')
def google_callback():
    # Verify state parameter
    state = request.args.get('state')
    if not state or state != session.get('oauth_state'):
        return jsonify({'error': 'Invalid state parameter'}), 400
    
    # Clear state after use
    session.pop('oauth_state', None)
    
    code = request.args.get('code')
    if not code:
        return jsonify({'error': 'No authorization code'}), 400
    
    # Exchange code for token
    token_response = requests.post('https://oauth2.googleapis.com/token', data={
        'code': code,
        'client_id': CLIENT_ID,
        'client_secret': CLIENT_SECRET,
        'redirect_uri': url_for('google_callback', _external=True),
        'grant_type': 'authorization_code',
    })
    
    if token_response.status_code != 200:
        return jsonify({'error': 'Token exchange failed'}), 400
    
    token_data = token_response.json()
    access_token = token_data['access_token']
    
    # Get user info
    user_response = requests.get('https://www.googleapis.com/oauth2/v2/userinfo',
                                 headers={'Authorization': f'Bearer {access_token}'})
    
    if user_response.status_code != 200:
        return jsonify({'error': 'Failed to get user info'}), 400
    
    user_info = user_response.json()
    
    # Create or update user
    user = get_or_create_user(user_info['email'], user_info['name'])
    
    # Create session
    session_id = create_session(user['id'])
    session['session_id'] = session_id
    
    return redirect('/')
```

### 9. Multi-Factor Authentication (MFA) Bypass

**Vulnerable patterns:**

```python
# Python - WRONG: MFA check can be skipped
@app.route('/login', methods=['POST'])
def login():
    username = request.form['username']
    password = request.form['password']
    
    if verify_password(username, password):
        user = get_user(username)
        if user['mfa_enabled']:
            session['pending_mfa'] = user['id']
            return redirect('/mfa')
        else:
            session['user_id'] = user['id']
            return redirect('/dashboard')

@app.route('/dashboard')
def dashboard():
    # WRONG: Doesn't check if MFA was completed
    if 'user_id' in session or 'pending_mfa' in session:
        return render_template('dashboard.html')
    return redirect('/login')
```

**Impact**: Attacker can bypass MFA by going directly to protected pages after password authentication.

**Fix:**

```python
# Python - CORRECT: Enforce MFA completion
@app.route('/login', methods=['POST'])
def login():
    username = request.form['username']
    password = request.form['password']
    
    if verify_password(username, password):
        user = get_user(username)
        if user['mfa_enabled']:
            session['pending_mfa'] = user['id']
            session['mfa_required'] = True
            return redirect('/mfa')
        else:
            session['user_id'] = user['id']
            session['mfa_required'] = False
            return redirect('/dashboard')
    
    return jsonify({'error': 'Invalid credentials'}), 401

def require_auth_with_mfa(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Check if user is authenticated
        if 'user_id' not in session:
            return redirect('/login')
        
        # Check if MFA is required but not completed
        if session.get('mfa_required') and not session.get('mfa_verified'):
            return redirect('/mfa')
        
        return f(*args, **kwargs)
    return decorated_function

@app.route('/mfa', methods=['GET', 'POST'])
def mfa():
    if 'pending_mfa' not in session:
        return redirect('/login')
    
    if request.method == 'POST':
        code = request.form['code']
        user_id = session['pending_mfa']
        
        if verify_mfa_code(user_id, code):
            session['user_id'] = user_id
            session['mfa_verified'] = True
            session.pop('pending_mfa', None)
            return redirect('/dashboard')
        
        return jsonify({'error': 'Invalid MFA code'}), 401
    
    return render_template('mfa.html')

@app.route('/dashboard')
@require_auth_with_mfa
def dashboard():
    return render_template('dashboard.html')
```

### 10. API Key Security

**Vulnerable patterns:**

```python
# Python - WRONG: API keys with no expiration or rotation
API_KEYS = {
    'abc123': {'user_id': 1, 'permissions': ['read', 'write']},
    'xyz789': {'user_id': 2, 'permissions': ['read']},
}

@app.route('/api/data')
def get_data():
    api_key = request.headers.get('X-API-Key')
    if api_key in API_KEYS:
        return jsonify({'data': 'sensitive data'})
    return jsonify({'error': 'Invalid API key'}), 401

# WRONG: API keys with full access
def verify_api_key(api_key):
    return api_key in API_KEYS  # No permission checking
```

**Fix:**

```python
# Python - CORRECT: Secure API key management
import secrets
from datetime import datetime, timedelta

def generate_api_key(user_id, name, permissions, expires_days=90):
    api_key = f"sk_{secrets.token_urlsafe(32)}"
    expires_at = datetime.utcnow() + timedelta(days=expires_days)
    
    db.execute("""
        INSERT INTO api_keys (key, user_id, name, permissions, expires_at, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (api_key, user_id, name, json.dumps(permissions), expires_at, datetime.utcnow()))
    
    return api_key

def verify_api_key(api_key, required_permission=None):
    key_data = db.execute("""
        SELECT * FROM api_keys 
        WHERE key = ? AND expires_at > ? AND revoked = 0
    """, (api_key, datetime.utcnow())).fetchone()
    
    if not key_data:
        return None
    
    # Update last used timestamp
    db.execute("""
        UPDATE api_keys 
        SET last_used = ?
        WHERE key = ?
    """, (datetime.utcnow(), api_key))
    
    permissions = json.loads(key_data['permissions'])
    
    if required_permission and required_permission not in permissions:
        return None
    
    return {
        'user_id': key_data['user_id'],
        'permissions': permissions
    }

def require_api_key(permission=None):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            api_key = request.headers.get('X-API-Key')
            if not api_key:
                return jsonify({'error': 'API key required'}), 401
            
            key_data = verify_api_key(api_key, permission)
            if not key_data:
                return jsonify({'error': 'Invalid or insufficient API key'}), 403
            
            request.api_user_id = key_data['user_id']
            request.api_permissions = key_data['permissions']
            
            return f(*args, **kwargs)
        return decorated_function
    return decorator

@app.route('/api/data')
@require_api_key('read')
def get_data():
    return jsonify({'data': 'sensitive data'})

@app.route('/api/data', methods=['POST'])
@require_api_key('write')
def create_data():
    # Only API keys with 'write' permission can access
    return jsonify({'status': 'created'})

def revoke_api_key(api_key):
    db.execute("UPDATE api_keys SET revoked = 1 WHERE key = ?", (api_key,))
```

## Detection Checklist

- [ ] JWT tokens are verified with signature checking
- [ ] Only specific algorithms are allowed for JWT
- [ ] Passwords are hashed with bcrypt or Argon2
- [ ] Password reset tokens are cryptographically secure and expire
- [ ] All protected endpoints require authentication
- [ ] Authorization checks verify resource ownership (no IDOR)
- [ ] Session IDs are cryptographically random
- [ ] Sessions expire and are cleaned up
- [ ] Session IDs are regenerated after login
- [ ] OAuth flows use state parameter for CSRF protection
- [ ] MFA cannot be bypassed
- [ ] API keys have expiration and permission scoping
- [ ] Failed login attempts are rate limited
- [ ] Account lockout after multiple failed attempts
- [ ] Sensitive operations require re-authentication

## Common AI Assistant Mistakes

1. **Using jwt.decode() without verification** - Most common JWT vulnerability
2. **Accepting any JWT algorithm** - Enables algorithm confusion attacks
3. **Using MD5/SHA256 for passwords** - Fast hashing enables brute force
4. **No authorization checks** - Authentication without authorization
5. **Client-side user_id** - Trusting user-provided identity
6. **Predictable tokens** - Using timestamps or sequential IDs
7. **No session expiration** - Sessions valid forever
8. **Missing CSRF protection** - State-changing operations without tokens

## Remediation Priority

1. **Critical** (immediate):
   - Fix JWT verification
   - Add authentication to unprotected endpoints
   - Fix IDOR vulnerabilities

2. **High** (within 24 hours):
   - Upgrade password hashing to bcrypt/Argon2
   - Add authorization checks
   - Implement session expiration

3. **Medium** (within 1 week):
   - Add MFA support
   - Implement API key rotation
   - Add rate limiting to auth endpoints

4. **Low** (within 1 month):
   - Add account lockout
   - Implement password complexity requirements
   - Add security logging
