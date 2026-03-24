# Vibe Security Enhanced - Skill Improvements Implementation Plan

**Date:** 2026-03-24  
**Goal:** Enhance the security skill with severity scoring, auto-fix patterns, and language-specific guidance  
**Approach:** Incremental enhancement of existing files

---

## Architecture

Enhance existing structure without adding new files:
- **skill.md** - Add severity scoring system to output format
- **5 reference files** - Add Quick Fix Patterns and Framework-Specific sections
- **Installation scripts** - Add validation and safety checks

---

## Phase 1: Enhance skill.md (Core Scoring System)

### Changes to skill.md

**1.1 Add Risk Scoring Section (after "Severity Definitions")**

Insert new section explaining the quantitative scoring system:
- Formula: Exploitability (0-40) + Impact (0-40) + Prevalence (0-20) = Score (0-100)
- Score interpretation ranges
- How to calculate each component

**1.2 Update Example Output Section**

Modify existing examples to include risk scores:
- Add score to each finding header
- Show score breakdown in parentheses
- Demonstrate how scores guide prioritization

**1.3 Update Summary Section Template**

Add risk score totals to the summary format.

### Testing Phase 1

- [ ] Read skill.md to verify changes
- [ ] Check markdown formatting is valid
- [ ] Verify examples are clear and actionable
- [ ] Confirm no existing content was lost

---

## Phase 2: Enhance Reference Files (Auto-Fix + Framework-Specific)

### 2.1 secrets-and-env.md

**Add Quick Fix Patterns section (after "Detection Checklist"):**
- Pattern 1: Hardcoded API key → Environment variable
- Pattern 2: Client-side secret → Server-side only
- Pattern 3: .env not in .gitignore → Add to .gitignore
- Pattern 4: Secret in git history → BFG cleanup

**Add Framework-Specific section (after "Quick Fix Patterns"):**
- Python (Django, Flask, FastAPI)
- JavaScript (Next.js, React, Express)
- Mobile (React Native, Expo)

### Testing 2.1
- [ ] Read file to verify changes
- [ ] Check all code examples are syntactically correct
- [ ] Verify diff format is clear
- [ ] Test that manual steps are actionable

### 2.2 authentication.md

**Add Quick Fix Patterns section:**
- Pattern 1: JWT without verification → Add verification
- Pattern 2: MD5 password hash → bcrypt
- Pattern 3: No session expiration → Add expiration
- Pattern 4: Missing auth decorator → Add @require_auth

**Add Framework-Specific section:**
- Django (django.contrib.auth, JWT, sessions)
- Flask (Flask-Login, Flask-JWT-Extended)
- Next.js (NextAuth.js, API routes)
- Express (Passport.js, express-session)

### Testing 2.2
- [ ] Read file to verify changes
- [ ] Validate all code examples
- [ ] Check framework-specific patterns are accurate
- [ ] Verify no duplication with existing content

### 2.3 database-security.md

**Add Quick Fix Patterns section:**
- Pattern 1: RLS disabled → Enable RLS with policies
- Pattern 2: Service role in client → Move to server
- Pattern 3: SQL injection → Parameterized query
- Pattern 4: No transaction locking → SELECT FOR UPDATE

**Add Framework-Specific section:**
- Supabase (RLS policies, anon vs service key)
- Firebase (Security Rules)
- Prisma (Row-level security, middleware)
- SQLAlchemy (ORM patterns, transactions)

### Testing 2.3
- [ ] Read file to verify changes
- [ ] Test SQL examples are valid
- [ ] Check framework patterns match best practices
- [ ] Verify security guidance is sound

### 2.4 input-validation.md

**Add Quick Fix Patterns section:**
- Pattern 1: String interpolation in SQL → Parameterized query
- Pattern 2: shell=True → shell=False with list args
- Pattern 3: No input validation → Add validation
- Pattern 4: Path traversal → Path sanitization

**Add Framework-Specific section:**
- Python (Pydantic, marshmallow, Django forms)
- JavaScript (Joi, Yup, Zod)
- SQL (SQLAlchemy, Prisma, TypeORM)

### Testing 2.4
- [ ] Read file to verify changes
- [ ] Validate injection examples
- [ ] Check validation library usage is correct
- [ ] Verify patterns prevent actual attacks

### 2.5 financial-security.md

**Add Quick Fix Patterns section:**
- Pattern 1: Float for money → Decimal
- Pattern 2: Client-side price → Server-side lookup
- Pattern 3: No transaction lock → SELECT FOR UPDATE
- Pattern 4: Missing audit log → Add comprehensive logging

**Add Framework-Specific section:**
- Python (decimal module, SQLAlchemy transactions)
- JavaScript (decimal.js, dinero.js)
- Stripe (webhook verification, idempotency)
- Trading APIs (CCXT patterns, order validation)

### Testing 2.5
- [ ] Read file to verify changes
- [ ] Test decimal arithmetic examples
- [ ] Verify transaction patterns are safe
- [ ] Check financial calculations are precise

---

## Phase 3: Enhance Installation Scripts

### 3.1 INSTALL.sh

**Add validation:**
- Check if vibe-security-enhanced directory exists
- Warn if destination already has installation
- Verify critical files exist before copying

**Add safety:**
- Prompt for confirmation on overwrite
- Show what will be installed
- Provide rollback instructions

### Testing 3.1
- [ ] Run script in test environment
- [ ] Verify validation catches missing source
- [ ] Test overwrite confirmation works
- [ ] Check error messages are helpful

### 3.2 INSTALL.bat

**Add same validation and safety as INSTALL.sh:**
- Directory existence check
- Overwrite confirmation
- File verification

### Testing 3.2
- [ ] Test on Windows (if available) or verify syntax
- [ ] Check batch script logic is correct
- [ ] Verify error handling works

### 3.3 INSTALL-ALL.sh

**Add validation for both components:**
- Check superpowers-skills directory exists
- Check vibe-security-enhanced directory exists
- Verify all required files present

### Testing 3.3
- [ ] Run script in test environment
- [ ] Verify both components install correctly
- [ ] Test error handling for missing directories

### 3.4 INSTALL-ALL.bat

**Add same validation as INSTALL-ALL.sh**

### Testing 3.4
- [ ] Verify batch script syntax
- [ ] Check logic matches shell script
- [ ] Test error messages

---

## Implementation Order

1. ✅ Create .gitignore (COMPLETED)
2. ✅ Create this implementation plan (COMPLETED)
3. Phase 1: Enhance skill.md
4. Phase 2.1: Enhance secrets-and-env.md
5. Phase 2.2: Enhance authentication.md
6. Phase 2.3: Enhance database-security.md
7. Phase 2.4: Enhance input-validation.md
8. Phase 2.5: Enhance financial-security.md
9. Phase 3.1: Enhance INSTALL.sh
10. Phase 3.2: Enhance INSTALL.bat
11. Phase 3.3: Enhance INSTALL-ALL.sh
12. Phase 3.4: Enhance INSTALL-ALL.bat
13. Final verification and testing

---

## Success Criteria

- [ ] All files enhanced with new sections
- [ ] No existing content lost or broken
- [ ] All code examples are syntactically valid
- [ ] Markdown formatting is correct
- [ ] Installation scripts have validation
- [ ] All tests pass for each phase
- [ ] Documentation is clear and actionable

---

## Rollback Plan

If any phase fails:
1. Git revert to previous commit
2. Review what went wrong
3. Fix the issue
4. Re-test before proceeding

---

## Notes

- Test after EACH step before proceeding
- Do not proceed to next phase until current phase tests pass
- Keep changes focused and incremental
- Maintain existing structure and style
