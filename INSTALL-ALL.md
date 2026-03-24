# Unified Installation Guide

This installer sets up all three frameworks for your AI assistant:

1. **Superpowers Skills Framework** - Systematic development workflows
2. **Vibe Security Enhanced** - Comprehensive security auditing
3. **Engineering Skills** - 18 senior engineering role skills

## Quick Install

### Windows

Double-click `INSTALL-ALL.bat` or run:

```cmd
INSTALL-ALL.bat
```

### Mac / Linux

```bash
chmod +x INSTALL-ALL.sh
./INSTALL-ALL.sh
```

## Installation Options

The installer will ask you to choose:

1. **Kiro (user-level)** - Applies to all your Kiro projects
2. **Kiro (project-level)** - Applies to one specific project
3. **Claude Code (user-level)** - All Claude Code projects
4. **Claude Code (project-level)** - One Claude Code project
5. **Cursor (user-level)** - All Cursor projects
6. **Custom path** - Specify your own installation directory
7. **Install for all** - Installs for Kiro, Claude Code, and Cursor

## What Gets Installed

### Engineering Skills (Steering Files)

18 senior engineering role skills installed alongside Superpowers:

**Core:** `senior-architect`, `senior-frontend`, `senior-backend`, `senior-fullstack`, `senior-qa`, `senior-devops`, `senior-secops`, `senior-security`, `code-reviewer`

**Cloud:** `aws-solution-architect`, `ms365-tenant-manager`

**Tools:** `tdd-guide`, `tech-stack-evaluator`

**AI/Data:** `senior-data-scientist`, `senior-data-engineer`, `senior-ml-engineer`, `senior-prompt-engineer`, `senior-computer-vision`

Skills use `inclusion: manual` — activate with `#` in chat (e.g. `#senior-backend`).

### Superpowers Skills Framework (Steering Files)

**Cursor uses `.cursor/rules/` directory:**

Installed to: `~/.cursor/rules/superpowers/` and `~/.cursor/rules/security/`

Note: Cursor has a different architecture - it uses "rules" instead of separate steering/skills directories. The installer adapts the files to work with Cursor's system.

- 00-using-superpowers.md
- 01-brainstorming.md
- 02-test-driven-development.md
- 03-systematic-debugging.md
- 04-verification-before-completion.md
- 05-writing-plans.md
- 06-requesting-code-review.md
- README.md

### Vibe Security Enhanced (Skill)

Installed to: `~/.kiro/skills/vibe-security-enhanced/` (or equivalent)

- skill.md (main skill file)
- references/ (5 comprehensive security guides)

## After Installation

Both frameworks activate automatically:

**Superpowers activates when:**
- Starting new features (brainstorming)
- Implementing code (TDD)
- Fixing bugs (systematic debugging)
- Claiming completion (verification)
- Planning work (writing plans)
- Before commits (code review)

**Vibe Security activates when:**
- Asking about security
- Requesting code reviews
- Working with auth, payments, databases
- Handling sensitive data
- Building APIs or financial systems

## Manual Installation

If you prefer to install manually:

```bash
# Superpowers (steering files)
cp -r superpowers-skills/steering/* ~/.kiro/steering/

# Vibe Security (skill)
cp -r vibe-security-enhanced ~/.kiro/skills/
```

## Verification

After installation, test by asking your AI assistant:

- "Start a new feature" (should trigger brainstorming workflow)
- "Check this code for security issues" (should trigger security audit)

## Troubleshooting

**Skills not activating?**
- Verify files are in correct directories
- Restart your AI assistant
- Check file permissions

**Want to customize?**
- Edit files in `~/.kiro/steering/` (Superpowers)
- Edit files in `~/.kiro/skills/vibe-security-enhanced/` (Security)

## Documentation

- Superpowers: See `superpowers-skills/README.md`
- Vibe Security: See `README.md` (root)

## Uninstallation

To remove:

```bash
# Remove Superpowers
rm -rf ~/.kiro/steering/00-using-superpowers.md
rm -rf ~/.kiro/steering/01-brainstorming.md
rm -rf ~/.kiro/steering/02-test-driven-development.md
rm -rf ~/.kiro/steering/03-systematic-debugging.md
rm -rf ~/.kiro/steering/04-verification-before-completion.md
rm -rf ~/.kiro/steering/05-writing-plans.md
rm -rf ~/.kiro/steering/06-requesting-code-review.md

# Remove Vibe Security
rm -rf ~/.kiro/skills/vibe-security-enhanced
```
