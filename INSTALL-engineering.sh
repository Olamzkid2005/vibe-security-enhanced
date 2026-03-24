#!/bin/bash

# Engineering Skills - Installation Script
# Installs 18 engineering role skills for Kiro, Claude Code, and Cursor

set -e

echo "==================================="
echo "Engineering Skills Installer"
echo "18 Senior Engineering Role Skills"
echo "Version 1.0"
echo "==================================="
echo ""

# Detect OS
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    HOME_DIR="$USERPROFILE"
else
    HOME_DIR="$HOME"
fi

# Validate source files
if [ ! -d "engineering-skills/steering" ]; then
    echo "ERROR: Source directory 'engineering-skills/steering' not found!"
    echo "Please run this script from the directory containing the engineering-skills folder."
    exit 1
fi

if [ ! -f "engineering-skills/steering/senior-architect.md" ]; then
    echo "ERROR: Required skill files not found in engineering-skills/steering/"
    echo "Installation package may be incomplete."
    exit 1
fi

SKILL_COUNT=$(ls engineering-skills/steering/*.md 2>/dev/null | wc -l)
echo "✓ Found $SKILL_COUNT skill files"
echo ""

# Backup existing installation
backup_existing() {
    local steering_dir=$1
    local backup_dir="${steering_dir}/_backup_engineering"

    local existing=$(ls "$steering_dir"/senior-*.md "$steering_dir"/code-reviewer.md "$steering_dir"/aws-solution-architect.md "$steering_dir"/ms365-tenant-manager.md "$steering_dir"/tdd-guide.md "$steering_dir"/tech-stack-evaluator.md 2>/dev/null | wc -l)

    if [ "$existing" -gt 0 ]; then
        echo "  Existing engineering skills found. Creating backup..."
        mkdir -p "$backup_dir"
        cp "$steering_dir"/senior-*.md "$backup_dir/" 2>/dev/null || true
        cp "$steering_dir"/code-reviewer.md "$backup_dir/" 2>/dev/null || true
        cp "$steering_dir"/aws-solution-architect.md "$backup_dir/" 2>/dev/null || true
        cp "$steering_dir"/ms365-tenant-manager.md "$backup_dir/" 2>/dev/null || true
        cp "$steering_dir"/tdd-guide.md "$backup_dir/" 2>/dev/null || true
        cp "$steering_dir"/tech-stack-evaluator.md "$backup_dir/" 2>/dev/null || true
        echo "  [OK] Backed up to: $backup_dir"
    fi
}

# Install to a steering directory
install_to() {
    local label=$1
    local steering_dir=$2

    echo ""
    echo "Installing for $label..."
    backup_existing "$steering_dir"
    mkdir -p "$steering_dir"
    cp engineering-skills/steering/*.md "$steering_dir/"

    local installed=$(ls "$steering_dir"/senior-*.md 2>/dev/null | wc -l)
    if [ "$installed" -gt 0 ]; then
        echo "✓ $label — $SKILL_COUNT skills installed to: $steering_dir"
    else
        echo "✗ $label — installation verification failed!"
        return 1
    fi
}

# Install for Cursor (uses rules directory)
install_cursor() {
    local rules_dir="$HOME_DIR/.cursor/rules/engineering"
    echo ""
    echo "Installing for Cursor..."
    mkdir -p "$rules_dir"
    cp engineering-skills/steering/*.md "$rules_dir/"
    echo "✓ Cursor — $SKILL_COUNT skills installed to: $rules_dir"
}

# Menu
echo "Select installation target:"
echo "1) Kiro (user-level - all projects)"
echo "2) Kiro (project-level - one project)"
echo "3) Claude Code (user-level)"
echo "4) Claude Code (project-level)"
echo "5) Cursor (user-level)"
echo "6) Custom path"
echo "7) Install for all (Kiro, Claude, Cursor)"
echo ""
read -p "Enter choice [1-7]: " choice

case $choice in
    1) install_to "Kiro (user-level)" "$HOME_DIR/.kiro/steering" ;;
    2)
        read -p "Enter project path: " project_path
        install_to "Kiro (project-level)" "$project_path/.kiro/steering"
        ;;
    3) install_to "Claude Code (user-level)" "$HOME_DIR/.claude/steering" ;;
    4)
        read -p "Enter project path: " project_path
        install_to "Claude Code (project-level)" "$project_path/.claude/steering"
        ;;
    5) install_cursor ;;
    6)
        read -p "Enter custom steering path: " custom_path
        install_to "Custom" "$custom_path"
        ;;
    7)
        install_to "Kiro" "$HOME_DIR/.kiro/steering"
        install_to "Claude Code" "$HOME_DIR/.claude/steering"
        install_cursor
        ;;
    *) echo "Invalid choice"; exit 1 ;;
esac

echo ""
echo "==================================="
echo "Installation Complete!"
echo "==================================="
echo ""
echo "18 Engineering Skills installed:"
echo "  Core:    senior-architect, senior-frontend, senior-backend,"
echo "           senior-fullstack, senior-qa, senior-devops,"
echo "           senior-secops, senior-security, code-reviewer"
echo "  Cloud:   aws-solution-architect, ms365-tenant-manager"
echo "  Tools:   tdd-guide, tech-stack-evaluator"
echo "  AI/Data: senior-data-scientist, senior-data-engineer,"
echo "           senior-ml-engineer, senior-prompt-engineer,"
echo "           senior-computer-vision"
echo ""
echo "Skills are set to manual inclusion — activate with # in chat:"
echo "  e.g. #senior-backend, #senior-devops, #tdd-guide"
echo ""
echo "See README.md for full documentation."
