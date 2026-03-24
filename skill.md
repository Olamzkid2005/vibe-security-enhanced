---
name: vibe-security-enhanced
description: Comprehensive security audit system for AI-generated codebases across all application types. Detects exposed secrets, broken access control, authentication bypasses, injection vulnerabilities, race conditions, financial logic flaws, ML security issues, API vulnerabilities, and deployment misconfigurations. Covers web apps, mobile apps, trading systems, ML pipelines, APIs, and microservices. Triggers on security keywords, code reviews, or when handling authentication, payments, databases, APIs, secrets, user data, financial operations, ML models, or sensitive business logic. Use for security audits, code reviews, vulnerability assessments, or proactive secure code generation.
license: MIT
metadata:
  author: Enhanced by Kiro AI based on Chris Raroque's vibe-security
  version: "2.0"
  coverage: "Universal - Web, Mobile, Trading, ML, APIs, Microservices"
---

# Comprehensive Security Audit System

Audit code for security vulnerabilities commonly introduced by AI code generation across all application types. These issues are prevalent in "vibe-coded" apps — projects built rapidly with AI assistance where security fundamentals get skipped.

AI assistants consistently introduce these patterns, leading to real breaches, stolen credentials, data leaks, financial losses, and system compromises. This skill exists to catch those mistakes before they ship.

## The Core Principles

1. **Never trust the client** - Every price, user ID, role, subscription status, feature flag, rate limit counter, and business logic decision must be validated or enforced server-side. If it exists only in the browser, mobile bundle, or request body, an attacker controls it.

2. **Defense in depth** - Multiple layers of security controls. If one fails, others should prevent exploitation.

3. **Fail securely** - When errors occur, fail to a secure state. Don't expose sensitive information in error messages.

4. **Least privilege** - Grant minimum necessary permissions. Database users, API keys, service accounts should have minimal required access.

5. **Validate everything** - All input is untrusted until proven otherwise. Validate type, format, range, and business logic constraints.

6. **Audit everything sensitive** - Log all security-relevant events with sufficient detail for forensic analysis.

## Audit Process

Examine the codebase systematically. For each category, load the relevant reference file only if the codebase uses that technology or pattern. Skip categories that aren't relevant to the current project.

### Core Security Categories (Always Check)

1. **Secrets & Environment Variables** — Scan for hardcoded API keys, tokens, credentials, private keys, database passwords, and encryption keys. Check for secrets exposed via client-side env var prefixes (`NEXT_PUBLIC_`, `VITE_`, `EXPO_PUBLIC_`, `REACT_APP_`). Verify sensitive files are in `.gitignore`. Check for secrets in git history, comments, and configuration files. See `references/secrets-and-env.md`.

2. **Authentication & Authorization** — Validate JWT handling, session management, password storage, MFA implementation, OAuth flows, API key validation, role-based access control (RBAC), and permission checks. Check for authentication bypasses, privilege escalation, and insecure direct object references (IDOR). See `references/authentication.md`.

3. **Input Validation & Injection Prevention** — Check for SQL injection, NoSQL injection, command injection, LDAP injection, XPath injection, template injection, and expression language injection. Verify all user input is validated, sanitized, and parameterized. Check for ReDoS (Regular Expression Denial of Service). See `references/input-validation.md`.

4. **Data Access & Database Security** — Verify database access controls, row-level security (RLS), query parameterization, ORM usage patterns, transaction isolation, and connection security. Check Supabase RLS policies, Firebase Security Rules, Convex auth guards, and traditional database permissions. See `references/database-security.md`.

5. **Error Handling & Information Disclosure** — Ensure error messages don't leak sensitive information (stack traces, database errors, file paths, internal state). Verify debug mode is disabled in production. Check logging doesn't expose secrets or PII. See `references/error-handling.md`.

6. **Cryptography & Data Protection** — Verify proper use of encryption algorithms, key management, password hashing (bcrypt, Argon2), secure random number generation, and TLS/SSL configuration. Check for weak algorithms (MD5, SHA1 for passwords, DES, RC4). See `references/cryptography.md`.

### Application-Type Specific Categories

7. **Web Application Security** — Check for XSS (reflected, stored, DOM-based), CSRF, clickjacking, open redirects, CORS misconfigurations, Content Security Policy, Subresource Integrity, and security headers. See `references/web-security.md`.

8. **API Security** — Verify API authentication, rate limiting, input validation, output encoding, versioning security, webhook signature verification, and API key rotation. Check for mass assignment, parameter pollution, and API enumeration. See `references/api-security.md`.

9. **Mobile Security** — Verify secure token storage (Keychain/Keystore, not AsyncStorage/SharedPreferences), API key protection via backend proxy, certificate pinning, deep link validation, biometric authentication security, and code obfuscation. Check for secrets in app bundles. See `references/mobile-security.md`.

10. **Financial & Trading Systems** — Check decimal precision (use Decimal, not float), overflow/underflow protection, atomic transactions, race condition prevention, position limits, fee calculations, price validation, balance checks, and audit logging. Verify server-side price lookups and transaction signing. See `references/financial-security.md`.

11. **Machine Learning & AI Systems** — Check model file integrity, training data validation, adversarial input protection, prediction confidence thresholds, model versioning, prompt injection prevention, output sanitization, and AI API key protection. Verify usage caps and cost controls. See `references/ml-security.md`.

12. **Real-Time & WebSocket Security** — Verify WebSocket authentication, message validation, rate limiting, connection hijacking prevention, and secure reconnection logic. Check for message injection and replay attacks. See `references/realtime-security.md`.

### Infrastructure & Operations Categories

13. **Rate Limiting & Abuse Prevention** — Ensure authentication endpoints, expensive operations, AI/LLM calls, payment operations, and public APIs have rate limits. Verify rate limit counters are server-side and tamper-proof. Check for distributed rate limiting in multi-instance deployments. See `references/rate-limiting.md`.

14. **Deployment & Configuration Security** — Verify production settings, security headers (HSTS, X-Frame-Options, CSP), source map handling, environment separation, CORS configuration, and default credentials. Check for exposed admin panels and debug endpoints. See `references/deployment.md`.

15. **Dependency & Supply Chain Security** — Check for outdated packages with known CVEs, unpinned dependencies, typosquatting risks, malicious packages, and license compliance. Verify dependency integrity and update policies. See `references/dependencies.md`.

16. **Logging, Monitoring & Incident Response** — Verify security event logging, audit trails, log integrity, PII handling in logs, log injection prevention, alerting configuration, and incident response procedures. Check for monitoring blind spots. See `references/logging-monitoring.md`.

17. **Concurrency & Race Conditions** — Check for TOCTOU (time-of-check-time-of-use) bugs, double-spend vulnerabilities, race conditions in critical sections, improper locking, deadlock risks, and transaction isolation issues. See `references/concurrency.md`.

18. **Session & State Management** — Verify session timeout, concurrent session limits, session fixation prevention, secure session storage, state persistence security, and cache security. Check for session hijacking vulnerabilities. See `references/session-management.md`.

19. **Network & Communication Security** — Verify TLS/SSL certificate validation, MITM protection, DNS security, SSRF prevention, webhook URL validation, and secure service-to-service communication. See `references/network-security.md`.

20. **Business Logic Vulnerabilities** — Check for logic flaws specific to the application domain (e.g., negative balances, circular references, workflow bypasses, state machine violations, timing attacks, and resource exhaustion). See `references/business-logic.md`.

21. **Compliance & Regulatory** — Verify GDPR compliance (data retention, right to deletion, consent), PCI DSS (if handling payments), HIPAA (if healthcare), SOC 2 controls, and industry-specific regulations. See `references/compliance.md`.

22. **Disaster Recovery & Resilience** — Check backup security (encryption, access control), recovery procedures, kill switch implementation, circuit breakers, graceful degradation, and data corruption detection. See `references/disaster-recovery.md`.

## Core Instructions

- **Report only genuine security issues** - Do not nitpick style, performance, or non-security concerns unless they have direct security implications.

- **Prioritize by exploitability and impact** - Focus on vulnerabilities that can be realistically exploited and cause significant harm. A theoretical vulnerability with no practical exploit path is lower priority than an easily exploitable flaw.

- **Context-aware auditing** - If the codebase doesn't use a particular technology (e.g., no Supabase, no ML models, no mobile app), skip that category entirely. Don't waste time on irrelevant checks.

- **Proactive secure code generation** - When generating new code, consult relevant reference files proactively to avoid introducing vulnerabilities in the first place. Prevention is better than detection.

- **Critical issues first** - If you find a critical issue (exposed secrets, disabled RLS, authentication bypass, SQL injection, hardcoded private keys), flag it immediately at the top of your response with a clear warning. Don't bury critical findings in long lists.

- **Provide actionable fixes** - Every finding must include a concrete, copy-paste-ready code fix. Show before/after examples with proper context.

- **Consider the full attack chain** - Sometimes multiple medium-severity issues combine to create a critical vulnerability. Look for these combinations.

- **Verify fixes don't break functionality** - Ensure security fixes maintain the intended business logic and don't introduce new bugs.

- **Check for security regression** - When reviewing changes, verify that previous security fixes haven't been undone or bypassed.

## Output Format

Organize findings by severity: **Critical** → **High** → **Medium** → **Low** → **Informational**.

### Severity Definitions

- **Critical**: Immediate exploitation possible with severe impact (data breach, financial loss, system compromise, credential theft, RCE)
- **High**: Exploitation likely with significant impact (privilege escalation, authentication bypass, sensitive data exposure)
- **Medium**: Exploitation possible with moderate impact (information disclosure, DoS, logic flaws)
- **Low**: Difficult to exploit or minimal impact (verbose errors, missing security headers)
- **Informational**: Security best practices, defense-in-depth improvements, no immediate risk

### Finding Format

For each issue:

1. **Location** - State the file path and relevant line numbers
2. **Vulnerability name** - Use standard terminology (e.g., "SQL Injection", "Hardcoded Credentials")
3. **Concrete impact** - Explain what an attacker could do with this vulnerability. Be specific about the attack scenario and consequences.
4. **Proof of concept** (if helpful) - Show how the vulnerability could be exploited
5. **Fix** - Provide before/after code with complete context

Skip categories with no issues. End with a prioritized action summary.

### Example Output

#### Critical

**`config/database.py:15-17` — Hardcoded database credentials in source code**

Database username and password are hardcoded in the source file. Anyone with access to the repository (including via git history) can extract these credentials and gain full database access, allowing them to read, modify, or delete all data.

```python
# Before - CRITICAL VULNERABILITY
db_config = {
    'host': 'prod-db.example.com',
    'user': 'admin',
    'password': 'P@ssw0rd123!',  # Hardcoded credential
    'database': 'production'
}

# After - Use environment variables
import os

db_config = {
    'host': os.environ['DB_HOST'],
    'user': os.environ['DB_USER'],
    'password': os.environ['DB_PASSWORD'],
    'database': os.environ['DB_NAME']
}
```

**Action required**: 
1. Move credentials to environment variables immediately
2. Rotate the exposed password
3. Audit git history and remove the credential from all commits
4. Review who had access to the repository during the exposure period

---

**`api/trades.py:45` — SQL Injection in trade history query**

User-supplied `symbol` parameter is directly interpolated into SQL query without sanitization. An attacker can inject arbitrary SQL to extract all user data, modify balances, or delete records.

Proof of concept:
```
GET /api/trades?symbol=BTC' UNION SELECT username,password,email FROM users--
```

```python
# Before - SQL INJECTION VULNERABILITY
def get_trades(symbol):
    query = f"SELECT * FROM trades WHERE symbol = '{symbol}'"
    return db.execute(query)

# After - Use parameterized queries
def get_trades(symbol):
    query = "SELECT * FROM trades WHERE symbol = ?"
    return db.execute(query, (symbol,))

# Or with SQLAlchemy ORM (preferred)
def get_trades(symbol):
    return db.session.query(Trade).filter(Trade.symbol == symbol).all()
```

---

#### High

**`trade_execution/order.py:78-82` — Race condition in balance check**

Balance check and deduction are not atomic. Two concurrent requests can both pass the balance check before either deducts, allowing double-spending.

Attack scenario:
1. User has $100 balance
2. User submits two $100 trade requests simultaneously
3. Both requests check balance (both see $100 available)
4. Both requests execute, spending $200 total

```python
# Before - RACE CONDITION
def execute_trade(user_id, amount):
    balance = get_balance(user_id)
    if balance >= amount:
        # Another request can execute here before deduction
        place_order(user_id, amount)
        deduct_balance(user_id, amount)
    else:
        raise InsufficientFunds()

# After - Use database transaction with row locking
def execute_trade(user_id, amount):
    with db.transaction():
        # SELECT FOR UPDATE locks the row
        user = db.session.query(User).filter(
            User.id == user_id
        ).with_for_update().first()
        
        if user.balance >= amount:
            place_order(user_id, amount)
            user.balance -= amount
            db.session.commit()
        else:
            raise InsufficientFunds()
```

---

**`frontend/routes.py:34` — Missing CSRF protection on state-changing endpoint**

The `/api/withdraw` endpoint accepts POST requests without CSRF token validation. An attacker can create a malicious website that submits withdrawal requests on behalf of authenticated users who visit the site.

```python
# Before - NO CSRF PROTECTION
@app.route('/api/withdraw', methods=['POST'])
@login_required
def withdraw():
    amount = request.json['amount']
    process_withdrawal(current_user.id, amount)
    return {'status': 'success'}

# After - Add CSRF protection
from flask_wtf.csrf import CSRFProtect

csrf = CSRFProtect(app)

@app.route('/api/withdraw', methods=['POST'])
@login_required
@csrf.exempt  # Only if using token-based auth
def withdraw():
    # For session-based auth, Flask-WTF handles CSRF automatically
    # For token-based auth, verify a custom CSRF token
    csrf_token = request.headers.get('X-CSRF-Token')
    if not verify_csrf_token(csrf_token, current_user.id):
        abort(403)
    
    amount = request.json['amount']
    process_withdrawal(current_user.id, amount)
    return {'status': 'success'}
```

---

#### Medium

**`ml_engine/predictor.py:56` — No input validation on prediction features**

Feature values are not validated before being passed to the ML model. Malicious or malformed input could cause crashes, incorrect predictions, or adversarial attacks on the model.

```python
# Before - NO VALIDATION
def predict(features):
    return model.predict(features)

# After - Validate input ranges and types
def predict(features):
    # Validate feature count
    if len(features) != EXPECTED_FEATURE_COUNT:
        raise ValueError(f"Expected {EXPECTED_FEATURE_COUNT} features, got {len(features)}")
    
    # Validate feature types and ranges
    validated_features = []
    for i, (value, (min_val, max_val)) in enumerate(zip(features, FEATURE_RANGES)):
        if not isinstance(value, (int, float)):
            raise ValueError(f"Feature {i} must be numeric")
        if not (min_val <= value <= max_val):
            raise ValueError(f"Feature {i} out of range [{min_val}, {max_val}]")
        validated_features.append(value)
    
    return model.predict(validated_features)
```

---

#### Low

**`app.py:12` — Debug mode enabled**

Flask debug mode is enabled, which exposes the interactive debugger and detailed error messages to users. This can leak sensitive information about the application structure and code.

```python
# Before
app.run(debug=True)

# After - Use environment variable
import os
app.run(debug=os.environ.get('FLASK_ENV') == 'development')
```

---

### Summary

**Immediate action required (Critical):**
1. Remove hardcoded database credentials and rotate password
2. Fix SQL injection in trade history endpoint - can lead to full database compromise
3. Audit git history for exposed secrets

**High priority (within 24 hours):**
4. Fix race condition in balance check - enables double-spending
5. Add CSRF protection to withdrawal endpoint - prevents unauthorized withdrawals

**Medium priority (within 1 week):**
6. Add input validation to ML prediction endpoint

**Low priority (next sprint):**
7. Disable debug mode in production

## When Generating Code

These rules apply proactively during code generation. Before writing code that touches:

- **Authentication/Authorization** → Consult `references/authentication.md`
- **Database queries** → Consult `references/database-security.md` and `references/input-validation.md`
- **User input** → Consult `references/input-validation.md`
- **Payments/Financial operations** → Consult `references/financial-security.md`
- **API endpoints** → Consult `references/api-security.md` and `references/rate-limiting.md`
- **Secrets/Credentials** → Consult `references/secrets-and-env.md`
- **ML models** → Consult `references/ml-security.md`
- **WebSockets/Real-time** → Consult `references/realtime-security.md`
- **Mobile code** → Consult `references/mobile-security.md`
- **Frontend** → Consult `references/web-security.md`

Prevention is always better than detection. Build security in from the start.

## Technology Detection

The skill automatically detects technologies in use and focuses on relevant checks:

- **Python**: Flask, FastAPI, Django, SQLAlchemy, Pandas, NumPy, TensorFlow, PyTorch
- **JavaScript/TypeScript**: React, Next.js, Vue, Express, NestJS, Node.js
- **Databases**: PostgreSQL, MySQL, MongoDB, Redis, Supabase, Firebase, DynamoDB
- **Mobile**: React Native, Expo, Flutter, Swift, Kotlin
- **ML/AI**: TensorFlow, PyTorch, scikit-learn, OpenAI API, Anthropic API
- **Payment**: Stripe, PayPal, Coinbase Commerce
- **Cloud**: AWS, GCP, Azure, Vercel, Netlify
- **Trading**: CCXT, Binance API, Coinbase API, Kraken API

## Reference Files

Core security references (always relevant):
- `references/secrets-and-env.md` — API keys, credentials, environment variables, git security
- `references/authentication.md` — JWT, sessions, passwords, MFA, OAuth, RBAC
- `references/input-validation.md` — Injection prevention, sanitization, validation patterns
- `references/database-security.md` — RLS, query security, transactions, access control
- `references/error-handling.md` — Secure error handling, logging, information disclosure
- `references/cryptography.md` — Encryption, hashing, key management, TLS/SSL

Application-specific references:
- `references/web-security.md` — XSS, CSRF, clickjacking, CORS, CSP, security headers
- `references/api-security.md` — API authentication, rate limiting, webhooks, versioning
- `references/mobile-security.md` — Secure storage, certificate pinning, deep links, biometrics
- `references/financial-security.md` — Decimal precision, atomic transactions, audit logging
- `references/ml-security.md` — Model security, adversarial inputs, prompt injection
- `references/realtime-security.md` — WebSocket security, message validation

Infrastructure references:
- `references/rate-limiting.md` — Rate limiting strategies, abuse prevention
- `references/deployment.md` — Production configuration, security headers, environment separation
- `references/dependencies.md` — Supply chain security, vulnerability scanning
- `references/logging-monitoring.md` — Security logging, audit trails, incident response
- `references/concurrency.md` — Race conditions, locking, transaction isolation
- `references/session-management.md` — Session security, state management
- `references/network-security.md` — TLS, MITM prevention, SSRF, DNS security
- `references/business-logic.md` — Domain-specific logic flaws
- `references/compliance.md` — GDPR, PCI DSS, HIPAA, regulatory requirements
- `references/disaster-recovery.md` — Backups, kill switches, circuit breakers

## Continuous Improvement

This skill is designed to evolve. As new vulnerability patterns emerge in AI-generated code, new reference files can be added without modifying the core audit process.

To add a new security category:
1. Create a new reference file in `references/`
2. Document the vulnerability patterns with examples
3. Provide concrete fixes with before/after code
4. The skill will automatically incorporate it into audits

## License

MIT License - Based on vibe-security by Chris Raroque, enhanced for comprehensive coverage.
