---
inclusion: fileMatch
fileMatchPattern: ["**/{auth,security,crypto,jwt,oauth,permission,rbac,middleware}/**/*.{ts,js,py,go}", "**/*.{ts,js,py,go}"]
---

# Senior Security Engineer

Security engineering guidance for threat modeling, secure architecture, vulnerability assessment, and secure code review.

---

## Core Principles

- **Defense in depth** — never rely on a single security control
- **Least privilege** — grant only the minimum access required
- **Assume breach** — design systems to limit blast radius
- **Fail secure** — deny by default; errors must not open access
- **No custom crypto** — use vetted libraries and approved algorithms only
- **Secrets never in code** — use environment variables or a secrets manager

---

## Threat Modeling (STRIDE)

Apply STRIDE to each element in the data flow diagram before designing mitigations.

| Threat | Property Violated | Mitigation Focus |
|--------|------------------|------------------|
| Spoofing | Authentication | MFA, certificates, strong auth |
| Tampering | Integrity | Signing, checksums, input validation |
| Repudiation | Non-repudiation | Audit logs, digital signatures |
| Information Disclosure | Confidentiality | Encryption, access controls |
| Denial of Service | Availability | Rate limiting, redundancy |
| Elevation of Privilege | Authorization | RBAC, least privilege |

**STRIDE applicability by DFD element:**

| Element | S | T | R | I | D | E |
|---------|---|---|---|---|---|---|
| External Entity | ✓ | | ✓ | | | |
| Process | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Data Store | | ✓ | ✓ | ✓ | ✓ | |
| Data Flow | | ✓ | | ✓ | ✓ | |

**Threat scoring (DREAD, each 1–10):** Damage + Reproducibility + Exploitability + Affected users + Discoverability. Prioritize by total score.

---

## Secure Architecture

### Defense-in-Depth Layers

| Layer | Controls |
|-------|----------|
| Perimeter | WAF, DDoS protection, rate limiting |
| Network | Segmentation, IDS/IPS, mTLS |
| Host | Patching, EDR, hardening |
| Application | Input validation, authentication, secure coding |
| Data | Encryption at rest and in transit, key management |

### Zero Trust Checklist

- [ ] Verify every request explicitly (no implicit trust from network location)
- [ ] Enforce least-privilege access on every resource
- [ ] Use short-lived tokens; rotate credentials regularly
- [ ] Log and monitor all access decisions
- [ ] Segment systems to limit lateral movement

### Authentication & Authorization

- Delegate to a proven IdP (Auth0, Cognito, Keycloak) rather than rolling your own
- Require MFA for privileged accounts
- Use RBAC or ABAC; check authorization on every endpoint — never assume
- Store passwords with bcrypt/Argon2 (never MD5/SHA-1)
- JWT: validate signature, expiry, audience, and issuer; use short expiry + refresh tokens
- Refresh tokens in `httpOnly` cookies only; never in `localStorage`

### Cryptography

- Symmetric encryption: AES-256-GCM
- Asymmetric: RSA-2048+ or ECDSA P-256+
- Hashing: SHA-256+ (never MD5/SHA-1 for security purposes)
- TLS 1.2 minimum; prefer TLS 1.3
- Manage keys via a KMS (AWS KMS, HashiCorp Vault); never hardcode keys

---

## Secure Code Review — Focus Areas

| Area | What to Check |
|------|--------------|
| Input validation | All external input validated and sanitized before use |
| Authentication | Every protected route/endpoint requires valid auth |
| Authorization | Permissions checked per request, not assumed from session |
| Cryptography | Approved algorithms; no custom crypto; keys not hardcoded |
| Secrets | No credentials, tokens, or keys in source code or logs |
| Error handling | Errors reveal no stack traces, internal paths, or sensitive data |
| Logging | Audit trail present; no PII or secrets logged |
| Dependencies | No known CVEs; dependencies pinned and regularly updated |

---

## Vulnerability Assessment

1. Run SAST (Semgrep, Bandit, CodeQL, ESLint security plugins)
2. Run DAST against a staging environment (OWASP ZAP, Burp Suite)
3. Scan dependencies for CVEs (`npm audit`, `pip-audit`, Snyk, Dependabot)
4. Review OWASP Top 10 exposure
5. Score findings by CVSS; address all Critical and High before release
6. Track remediation with owners and deadlines

---

## OWASP Top 10 — Quick Reference

| Risk | Key Mitigation |
|------|---------------|
| Broken Access Control | Enforce authz server-side on every request |
| Cryptographic Failures | Encrypt sensitive data; use TLS; no weak algorithms |
| Injection | Parameterized queries; strict input validation |
| Insecure Design | Threat model early; defense in depth |
| Security Misconfiguration | Harden defaults; disable unused features; review headers |
| Vulnerable Components | Audit dependencies; pin versions; automate CVE scanning |
| Auth Failures | MFA; secure session management; rate-limit login |
| Integrity Failures | Verify signatures on software and data pipelines |
| Logging Failures | Log auth events, access decisions, and errors centrally |
| SSRF | Allowlist outbound destinations; validate URLs server-side |

---

## Incident Response

1. **Detect & triage** — classify severity; page on-call if Critical
2. **Contain** — isolate affected systems; revoke compromised credentials
3. **Investigate** — establish timeline; identify root cause
4. **Eradicate** — remove threat; patch vulnerability
5. **Recover** — restore services; verify integrity before re-enabling
6. **Post-mortem** — document lessons learned; update runbooks and controls

---

## Security Tools Reference

| Category | Tools |
|----------|-------|
| SAST | Semgrep, Bandit, CodeQL, ESLint security |
| DAST | OWASP ZAP, Burp Suite |
| Dependency scanning | npm audit, pip-audit, Snyk, Dependabot |
| Secrets scanning | truffleHog, detect-secrets, git-secrets |
| Container security | Trivy, Grype, Clair |
| IaC security | Checkov, tfsec, cfn-nag |
| Key management | AWS KMS, HashiCorp Vault, Azure Key Vault |
