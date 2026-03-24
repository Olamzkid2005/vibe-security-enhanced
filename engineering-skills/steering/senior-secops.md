---
inclusion: fileMatch
fileMatchPattern: ["**/*.tf", "**/*.yaml", "**/*.yml", "**/Dockerfile", "**/docker-compose.*", "**/.github/workflows/**", "**/security/**", "**/*.env*", "**/auth/**", "**/secrets/**"]
---

# Senior SecOps Engineer

Security operations guidance covering vulnerability management, secure coding patterns, compliance verification, and CI/CD security automation.

---

## When to Apply This Guidance

- Conducting a security review or audit
- Responding to a CVE or security incident
- Implementing authentication, authorization, or secrets management
- Hardening infrastructure or containers
- Checking OWASP Top 10 exposure
- Enforcing security controls in CI/CD pipelines
- Verifying compliance against SOC 2, PCI-DSS, HIPAA, or GDPR

---

## Secure Coding Patterns

### Secrets Management

- Never hardcode secrets, API keys, tokens, or credentials in source code
- Use environment variables or a secrets manager (Vault, AWS Secrets Manager, etc.)
- Validate all required secrets at startup; fail fast if missing
- Rotate secrets regularly; treat leaked secrets as compromised immediately

```python
# Bad
DB_PASSWORD = "supersecret123"

# Good
import os
DB_PASSWORD = os.environ["DB_PASSWORD"]  # fails loudly if missing
```

### Input Validation and Injection Prevention

- Use parameterized queries — never concatenate user input into SQL
- Validate and sanitize all user input at the boundary (not deep in business logic)
- Avoid `eval`, `exec`, and `shell=True` with any user-controlled data
- Sanitize output rendered to HTML; use framework-provided escaping

```python
# Bad — SQL injection
cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")

# Good — parameterized
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
```

### Authentication and Authorization

- Hash passwords with bcrypt, argon2, or scrypt — never MD5/SHA1
- Enforce MFA for privileged accounts
- Validate authorization on every request — do not rely on UI-only controls
- Use short-lived JWTs (≤15 min access tokens); store refresh tokens in `httpOnly` cookies
- Implement rate limiting on auth endpoints

### Cryptography

- TLS 1.2+ everywhere; disable older protocols
- Use AES-256-GCM for symmetric encryption
- Never roll your own crypto — use established libraries
- Encrypt sensitive data at rest; document what is encrypted and why

---

## Vulnerability Detection Checklist

### Code-Level

- [ ] Hardcoded secrets (API keys, passwords, tokens, private keys)
- [ ] SQL/NoSQL injection (string concatenation with user input)
- [ ] XSS (unsafe `innerHTML`, unescaped template output)
- [ ] Command injection (`shell=True`, `exec`/`eval` with user data)
- [ ] Path traversal (file operations with unsanitized user input)
- [ ] Insecure deserialization (pickle, YAML load with untrusted data)
- [ ] SSRF (outbound requests to user-supplied URLs without validation)

### Dependency Scanning

Scan these files for known CVEs:

| Ecosystem | Files |
|-----------|-------|
| npm | `package.json`, `package-lock.json` |
| Python | `requirements.txt`, `pyproject.toml` |
| Go | `go.mod` |
| Containers | `Dockerfile`, base image tags |

Run: `npm audit --audit-level=high`, `pip-audit`, `trivy image $IMAGE`

---

## OWASP Top 10 — Quick Reference

| # | Risk | Key Control |
|---|------|-------------|
| A01 | Broken Access Control | Enforce authz server-side on every endpoint |
| A02 | Cryptographic Failures | TLS everywhere; strong algorithms only |
| A03 | Injection | Parameterized queries; validate all input |
| A04 | Insecure Design | Threat model early; apply secure design patterns |
| A05 | Security Misconfiguration | Least privilege; disable defaults; harden configs |
| A06 | Vulnerable Components | Dependency scanning in CI; pin versions |
| A07 | Auth Failures | MFA; secure session management; rate limiting |
| A08 | Software Integrity | Verify supply chain; use SBOMs; sign artifacts |
| A09 | Logging Failures | Audit logs for auth events, data access, errors |
| A10 | SSRF | Allowlist outbound destinations; block internal ranges |

---

## CI/CD Security Gates

Add these steps to every pipeline:

```yaml
security:
  steps:
    - name: Secret scanning
      run: detect-secrets scan --all-files
    - name: SAST
      run: semgrep --config=auto src/
    - name: Dependency audit
      run: npm audit --audit-level=high
    - name: Container scan
      run: trivy image $IMAGE_TAG --exit-code 1 --severity HIGH,CRITICAL
```

Block merges on: critical CVEs, hardcoded secrets, high-severity SAST findings.

---

## Compliance Frameworks

| Framework | Key Controls |
|-----------|-------------|
| SOC 2 | Access control, availability, confidentiality, processing integrity, audit logging |
| PCI-DSS | Cardholder data encryption, network segmentation, vulnerability management, access logs |
| HIPAA | PHI encryption at rest and in transit, access controls, audit logs, breach notification |
| GDPR | Data minimization, consent management, right to erasure, DPA agreements, breach reporting |

### Compliance Verification Steps

1. Access control — verify authz enforced on every endpoint and resource
2. Encryption — confirm TLS in transit and encryption at rest for sensitive data
3. Audit logging — confirm auth events, data access, and errors are logged with timestamps
4. Authentication strength — MFA enabled, passwords hashed with modern algorithm
5. CI/CD controls — secret scanning, SAST, and dependency audit gates active

---

## Incident Response

### CVE Remediation

1. Identify affected packages and versions
2. Assess exploitability in your specific context (is the vulnerable code path reachable?)
3. Find patched version or accepted mitigation
4. Update dependency, run full test suite, verify fix
5. Document remediation: CVE ID, affected version, fix version, date, notes

### Security Audit Workflow

1. Scan code for vulnerabilities — resolve critical findings before continuing
2. Scan dependencies for CVEs — patch critical CVEs before continuing
3. Verify compliance controls — address critical gaps
4. Generate consolidated report with findings ranked by severity
5. Create remediation backlog: Critical → High → Medium → Low
