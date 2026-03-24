# How to Install Superpowers Skills Framework

## Windows

Double-click `INSTALL.bat` and follow the prompts.

Or run it from the command line:

```cmd
INSTALL.bat
```

## Mac / Linux

```bash
chmod +x INSTALL.sh
./INSTALL.sh
```

## What the installer asks

1. Which AI assistant to install for (Kiro, Claude Code, Cursor, or all)
2. User-level (all projects) or project-level (one project)

That's it. Once installed, the skills automatically guide your development workflow:

- **Brainstorming** - Design before implementation
- **TDD** - Test-driven development (RED-GREEN-REFACTOR)
- **Systematic Debugging** - Root cause analysis
- **Verification** - Evidence-based completion
- **Planning** - Bite-sized task breakdown
- **Code Review** - Quality gates before merging

## Manual Installation

If you prefer to install manually:

### Kiro (User-level)
```bash
cp -r steering/* ~/.kiro/steering/
```

### Kiro (Project-level)
```bash
cp -r steering/* /path/to/project/.kiro/steering/
```

### Claude Code (User-level)
```bash
cp -r steering/* ~/.claude/steering/
```

### Cursor (User-level)
```bash
cp -r steering/* ~/.cursor/steering/
```

## Verification

After installation, the skills will automatically activate based on context. You can verify by asking your AI assistant to start a new feature - it should follow the brainstorming workflow.
