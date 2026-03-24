# Vibe Security Enhanced - Export Package

## Overview

This is a comprehensive security audit skill for AI coding assistants (Kiro, Claude Code, Cursor, etc.). It detects and prevents common security vulnerabilities in AI-generated code across all application types.

**Version:** 2.0  
**License:** MIT  
**Based on:** [vibe-security by Chris Raroque](https://github.com/raroque/vibe-security-skill)

## What's Included

This skill provides:

- **22 Security Categories** covering all application types
- **5 Core Reference Files** (with 17 more planned)
- **Detailed vulnerability patterns** with before/after code examples
- **Proof of concept exploits** for understanding impact
- **Technology-specific checks** (Python, JavaScript, Supabase, Firebase, etc.)
- **Prioritized remediation guidance**

## Coverage

### Application Types
- Web applications (React, Next.js, Vue, Flask, Django, FastAPI)
- Mobile apps (React Native, Expo, Flutter)
- Trading systems (CCXT, Binance, Coinbase APIs)
- ML/AI systems (TensorFlow, PyTorch, OpenAI, Anthropic)
- APIs and microservices
- Real-time applications (WebSockets)

### Security Categories

**Core Security (Always Checked):**
1. Secrets & Environment Variables
2. Authentication & Authorization
3. Input Validation & Injection Prevention
4. Database Security
5. Error Handling & Information Disclosure
6. Cryptography & Data Protection

**Application-Specific:**
7. Web Application Security
8. API Security
9. Mobile Security
10. Financial & Trading Systems
11. Machine Learning & AI Systems
12. Real-Time & WebSocket Security

**Infrastructure & Operations:**
13. Rate Limiting & Abuse Prevention
14. Deployment & Configuration Security
15. Dependency & Supply Chain Security
16. Logging, Monitoring & Incident Response
17. Concurrency & Race Conditions
18. Session & State Management
19. Network & Communication Security
20. Business Logic Vulnerabilities
21. Compliance & Regulatory
22. Disaster Recovery & Resilience

## Installation

### For Kiro IDE

1. Copy the entire `vibe-security-enhanced` folder to your skills directory:

```bash
# User-level (applies to all projects)
cp -r vibe-security-enhanced ~/.kiro/skills/

# Project-level (applies to one project)
cp -r vibe-security-enhanced /path/to/project/.kiro/skills/
```

2. The skill will automatically activate when you:
   - Ask about security
   - Request code reviews
   - Mention authentication, payments, databases, APIs, secrets
   - Work with financial operations, ML models, or sensitive data

### For Claude Code

1. Copy the folder to Claude's skills directory:

```bash
# User-level
cp -r vibe-security-enhanced ~/.claude/skills/

# Project-level
cp -r vibe-security-enhanced /path/to/project/.claude/skills/
```

2. Use `/vibe-security-enhanced` to trigger audits, or ask naturally:
   - "check my code for security issues"
   - "is this safe?"
   - "audit this project"
   - "review for vulnerabilities"

### For Cursor

1. Copy the folder to Cursor's skills directory:

```bash
cp -r vibe-security-enhanced ~/.cursor/skills/
```

2. The skill will activate automatically based on context.

### For Other AI Assistants

If your AI assistant supports skills/context files:

1. Copy the `skill.md` file and `references/` folder to your assistant's configuration directory
2. Refer to your assistant's documentation for the exact location

## Usage

### Automatic Activation

The skill automatically activates when you:
- Mention security-related keywords
- Work with authentication, payments, or sensitive data
- Request code reviews
- Ask "is this safe?" or "check my code"

### Manual Activation

Explicitly request a security audit:
- "Run a security audit on this codebase"
- "Check for vulnerabilities in [file/folder]"
- "Review this code for security issues"

### During Code Generation

The skill proactively prevents vulnerabilities when generating code that involves:
- Authentication/Authorization
- Database queries
- User input handling
- Payment processing
- API endpoints
- Secrets/Credentials
- ML models
- WebSockets
- Mobile code
- Frontend code

## Reference Files

### Currently Included (5 files)

1. **secrets-and-env.md** - API keys, credentials, environment variables, git security
2. **authentication.md** - JWT, sessions, passwords, MFA, OAuth, RBAC
3. **input-validation.md** - Injection prevention, sanitization, validation patterns
4. **database-security.md** - RLS, query security, transactions, access control
5. **financial-security.md** - Decimal precision, atomic transactions, audit logging

### Planned (17 files)

6. error-handling.md
7. cryptography.md
8. web-security.md
9. api-security.md
10. mobile-security.md
11. ml-security.md
12. realtime-security.md
13. rate-limiting.md
14. deployment.md
15. dependencies.md
16. logging-monitoring.md
17. concurrency.md
18. session-management.md
19. network-security.md
20. business-logic.md
21. compliance.md
22. disaster-recovery.md

## Example Output

The skill provides detailed findings organized by severity:

```
#### Critical

**`config/database.py:15-17` — Hardcoded database credentials**

Database username and password are hardcoded. Anyone with repository 
access can extract these credentials and gain full database access.

[Before/After code example]

**Action required:**
1. Move credentials to environment variables immediately
2. Rotate the exposed password
3. Audit git history
```

## Customization

### Adding New Checks

1. Create a new reference file in `references/`
2. Follow the existing format:
   - Overview section
   - Critical Patterns to Detect
   - Before/After code examples
   - Impact explanations
   - Detection checklist
   - Common AI mistakes
   - Remediation priorities

3. Update `skill.md` to reference the new file

### Modifying Existing Checks

Edit the relevant reference file in `references/`. The skill will automatically use the updated checks.

### Technology-Specific Customization

The skill auto-detects technologies. To add support for new frameworks:

1. Add detection patterns to the "Technology Detection" section in `skill.md`
2. Create technology-specific reference files if needed

## Common Vulnerabilities Detected

### Critical
- Hardcoded secrets and API keys
- SQL injection
- Disabled Row-Level Security (Supabase)
- Service role key exposure
- Command injection
- Authentication bypasses

### High
- JWT verification failures
- Weak password storage
- Race conditions in financial operations
- IDOR (Insecure Direct Object References)
- Missing CSRF protection
- Client-side price manipulation

### Medium
- Missing input validation
- Information disclosure in errors
- Stale price data in trading
- Missing audit logging
- Template injection
- Path traversal

### Low
- Debug mode enabled in production
- Missing security headers
- Verbose error messages

## Best Practices

1. **Run audits regularly** - Before major releases, after AI-generated code, during code reviews
2. **Fix critical issues immediately** - Don't deploy with critical vulnerabilities
3. **Use during development** - Let the skill guide secure code generation
4. **Keep updated** - New vulnerability patterns are added regularly
5. **Customize for your stack** - Add project-specific checks as needed

## Contributing

To contribute improvements:

1. Add new vulnerability patterns to existing reference files
2. Create new reference files for uncovered categories
3. Improve detection accuracy
4. Add support for new frameworks/technologies
5. Share your customizations

## Support

For issues, questions, or contributions:
- Original vibe-security: https://github.com/raroque/vibe-security-skill
- This enhanced version: Created by Kiro AI

## License

MIT License

Based on vibe-security by Chris Raroque (@raroque) and the team at Aloa.
Enhanced for comprehensive coverage across all application types.

## Changelog

### Version 2.0 (Current)
- Expanded from 9 to 22 security categories
- Added 5 comprehensive reference files
- Added financial/trading security
- Added ML/AI security
- Added concurrency and race condition checks
- Added business logic vulnerability detection
- Universal coverage for all application types
- Detailed before/after code examples
- Proof of concept exploits
- Technology auto-detection

### Version 1.0 (Original)
- 9 security categories
- Focus on web applications
- Basic vulnerability detection
