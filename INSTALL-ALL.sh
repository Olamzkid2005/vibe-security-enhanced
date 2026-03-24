#!/bin/bash

# Unified Installer - Superpowers Skills + Vibe Security Enhanced
# Supports install, upgrade (with backup), and restore

set -e

echo "==================================="
echo "Unified Skills Installer"
echo "Superpowers + Vibe Security + Engineering"
echo "Version 2.0"
echo "==================================="
echo ""

# Detect OS
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    HOME_DIR="$USERPROFILE"
else
    HOME_DIR="$HOME"
fi

echo "What would you like to do?"
echo "1) Install / Upgrade"
echo "2) Restore from backup"
echo ""
read -p "Enter choice [1-2]: " action

case $action in
    1) do_install_menu ;;
    2) do_restore_menu ;;
    *) echo "Invalid choice"; exit 1 ;;
esac

# ===================================
# BACKUP FUNCTION
# ===================================
backup_existing() {
    local steering_dir=$1
    local skills_dir=$2
    local backup_dir="${steering_dir}/_backup"
    local backup_skills_dir="${skills_dir}/_backup"

    if [ -f "$steering_dir/00-using-superpowers.md" ]; then
        echo "  Existing installation found. Creating backup..."
        mkdir -p "$backup_dir"
        cp "$steering_dir"/*.md "$backup_dir/" 2>/dev/null || true
        echo "  [OK] Steering files backed up to: $backup_dir"
    fi

    if [ -f "$skills_dir/vibe-security-enhanced/skill.md" ]; then
        mkdir -p "$backup_skills_dir/vibe-security-enhanced"
        cp -r "$skills_dir/vibe-security-enhanced/." "$backup_skills_dir/vibe-security-enhanced/"
        echo "  [OK] Vibe Security backed up to: $backup_skills_dir/vibe-security-enhanced"
    fi
}

backup_cursor_existing() {
    local rules_dir="$HOME_DIR/.cursor/rules"
    local backup_dir="$rules_dir/_backup"

    if [ -f "$rules_dir/superpowers/00-using-superpowers.md" ]; then
        echo "  Existing Cursor installation found. Creating backup..."
        mkdir -p "$backup_dir/superpowers"
        cp "$rules_dir/superpowers/"* "$backup_dir/superpowers/" 2>/dev/null || true
        echo "  [OK] Superpowers backed up to: $backup_dir/superpowers"
    fi

    if [ -f "$rules_dir/security/skill.md" ]; then
        mkdir -p "$backup_dir/security"
        cp -r "$rules_dir/security/." "$backup_dir/security/"
        echo "  [OK] Vibe Security backed up to: $backup_dir/security"
    fi
}

# ===================================
# INSTALL FUNCTION
# ===================================
install_for_assistant() {
    local assistant=$1
    local steering_dir=$2
    local skills_dir=$3

    echo ""
    echo "Installing for $assistant..."

    # Backup first
    backup_existing "$steering_dir" "$skills_dir"

    # Install
    mkdir -p "$steering_dir"
    mkdir -p "$skills_dir"

    echo "  Installing Superpowers Skills Framework..."
    cp -r superpowers-skills/steering/* "$steering_dir/"
    echo "  [OK] Superpowers installed"

    echo "  Installing Vibe Security Enhanced..."
    cp -r vibe-security-enhanced "$skills_dir/"
    echo "  [OK] Vibe Security installed"

    if [ "$HAS_ENGINEERING" = true ]; then
        echo "  Installing Engineering Skills..."
        cp engineering-skills/steering/*.md "$steering_dir/"
        echo "  [OK] Engineering Skills installed (18 skills)"
    fi

    echo "✓ $assistant installation complete"
}

install_cursor() {
    local rules_dir="$HOME_DIR/.cursor/rules"

    echo ""
    echo "Installing for Cursor..."

    # Backup first
    backup_cursor_existing

    # Install
    mkdir -p "$rules_dir/superpowers"
    mkdir -p "$rules_dir/security"

    echo "  Installing Superpowers Skills Framework..."
    cp -r superpowers-skills/steering/* "$rules_dir/superpowers/"
    echo "  [OK] Superpowers installed"

    echo "  Installing Vibe Security Enhanced..."
    cp vibe-security-enhanced/skill.md "$rules_dir/security/"
    cp -r vibe-security-enhanced/references "$rules_dir/security/"
    echo "  [OK] Vibe Security installed"

    if [ "$HAS_ENGINEERING" = true ]; then
        echo "  Installing Engineering Skills..."
        mkdir -p "$rules_dir/engineering"
        cp engineering-skills/steering/*.md "$rules_dir/engineering/"
        echo "  [OK] Engineering Skills installed (18 skills)"
    fi

    echo "✓ Cursor installation complete"
}

# ===================================
# INSTALL MENU
# ===================================
do_install_menu() {
    # Validate source files
    if [ ! -f "superpowers-skills/steering/00-using-superpowers.md" ] || [ ! -f "vibe-security-enhanced/skill.md" ]; then
        echo "ERROR: Source files not found. Run this script from the package directory."
        exit 1
    fi

    HAS_ENGINEERING=false
    if [ -f "engineering-skills/steering/senior-architect.md" ]; then
        HAS_ENGINEERING=true
        echo "✓ Engineering skills found (18 skills)"
    fi

    echo ""
    echo "Select installation target:"
    echo "1) Kiro (user-level - all projects)"
    echo "2) Kiro (project-level - one project)"
    echo "3) Claude Code (user-level)"
    echo "4) Claude Code (project-level)"
    echo "5) Cursor (user-level)"
    echo "6) Custom path"
    echo "7) Install for all assistants (Kiro, Claude, Cursor)"
    echo ""
    read -p "Enter choice [1-7]: " choice

    case $choice in
        1)
            install_for_assistant "Kiro (user-level)" "$HOME_DIR/.kiro/steering" "$HOME_DIR/.kiro/skills"
            ;;
        2)
            read -p "Enter project path: " project_path
            install_for_assistant "Kiro (project-level)" "$project_path/.kiro/steering" "$project_path/.kiro/skills"
            ;;
        3)
            install_for_assistant "Claude Code (user-level)" "$HOME_DIR/.claude/steering" "$HOME_DIR/.claude/skills"
            ;;
        4)
            read -p "Enter project path: " project_path
            install_for_assistant "Claude Code (project-level)" "$project_path/.claude/steering" "$project_path/.claude/skills"
            ;;
        5)
            install_cursor
            ;;
        6)
            read -p "Enter custom installation path: " base_dir
            install_for_assistant "Custom" "$base_dir/steering" "$base_dir/skills"
            ;;
        7)
            install_for_assistant "Kiro" "$HOME_DIR/.kiro/steering" "$HOME_DIR/.kiro/skills"
            install_for_assistant "Claude Code" "$HOME_DIR/.claude/steering" "$HOME_DIR/.claude/skills"
            install_cursor
            ;;
        *)
            echo "Invalid choice"
            exit 1
            ;;
    esac

    print_install_done
}

# ===================================
# RESTORE MENU
# ===================================
do_restore_menu() {
    echo ""
    echo "Select which assistant to restore:"
    echo "1) Kiro (user-level)"
    echo "2) Claude Code (user-level)"
    echo "3) Cursor (user-level)"
    echo "4) Custom path"
    echo ""
    read -p "Enter choice [1-4]: " restore_choice

    case $restore_choice in
        1)
            restore_assistant "$HOME_DIR/.kiro/steering" "$HOME_DIR/.kiro/skills"
            ;;
        2)
            restore_assistant "$HOME_DIR/.claude/steering" "$HOME_DIR/.claude/skills"
            ;;
        3)
            restore_cursor
            ;;
        4)
            read -p "Enter custom installation path: " base_dir
            restore_assistant "$base_dir/steering" "$base_dir/skills"
            ;;
        *)
            echo "Invalid choice"
            exit 1
            ;;
    esac
}

restore_assistant() {
    local steering_dir=$1
    local skills_dir=$2
    local backup_dir="${steering_dir}/_backup"
    local backup_skills_dir="${skills_dir}/_backup"

    if [ ! -d "$backup_dir" ]; then
        echo "ERROR: No backup found at: $backup_dir"
        exit 1
    fi

    echo ""
    echo "Restoring from backup..."

    cp "$backup_dir"/*.md "$steering_dir/" 2>/dev/null || true
    echo "  [OK] Steering files restored from: $backup_dir"

    if [ -d "$backup_skills_dir/vibe-security-enhanced" ]; then
        cp -r "$backup_skills_dir/vibe-security-enhanced/." "$skills_dir/vibe-security-enhanced/"
        echo "  [OK] Vibe Security restored from: $backup_skills_dir"
    fi

    print_restore_done
}

restore_cursor() {
    local backup_dir="$HOME_DIR/.cursor/rules/_backup"

    if [ ! -d "$backup_dir" ]; then
        echo "ERROR: No backup found at: $backup_dir"
        exit 1
    fi

    echo ""
    echo "Restoring Cursor from backup..."

    if [ -d "$backup_dir/superpowers" ]; then
        cp "$backup_dir/superpowers/"* "$HOME_DIR/.cursor/rules/superpowers/" 2>/dev/null || true
        echo "  [OK] Superpowers rules restored"
    fi

    if [ -d "$backup_dir/security" ]; then
        cp -r "$backup_dir/security/." "$HOME_DIR/.cursor/rules/security/"
        echo "  [OK] Security rules restored"
    fi

    print_restore_done
}

# ===================================
# OUTPUT FUNCTIONS
# ===================================
print_install_done() {
    echo ""
    echo "==================================="
    echo "Installation Complete!"
    echo "==================================="
    echo ""
    echo "SUPERPOWERS SKILLS FRAMEWORK"
    echo "  - Design before implementation (brainstorming)"
    echo "  - Test-driven development (TDD)"
    echo "  - Systematic debugging (root cause analysis)"
    echo "  - Evidence-based verification"
    echo "  - Detailed planning"
    echo "  - Code review checklists"
    echo ""
    echo "VIBE SECURITY ENHANCED"
    echo "  - 22 security categories"
    echo "  - Automatic vulnerability detection"
    echo "  - Financial/trading security"
    echo "  - ML/AI security"
    echo "  - Comprehensive code audits"
    echo ""
    echo "ENGINEERING SKILLS (18 skills)"
    echo "  - senior-architect, senior-frontend, senior-backend"
    echo "  - senior-fullstack, senior-qa, senior-devops"
    echo "  - senior-secops, senior-security, code-reviewer"
    echo "  - aws-solution-architect, ms365-tenant-manager"
    echo "  - tdd-guide, tech-stack-evaluator"
    echo "  - senior-data-scientist, senior-data-engineer"
    echo "  - senior-ml-engineer, senior-prompt-engineer"
    echo "  - senior-computer-vision"
    echo ""
    echo "TIP: A backup of your previous version was saved."
    echo "     Run this installer again and choose option 2 to restore it."
    echo ""
    echo "Both frameworks activate automatically based on context."
    echo "See README.md files for full documentation."
}

print_restore_done() {
    echo ""
    echo "==================================="
    echo "Restore Complete!"
    echo "==================================="
    echo "Previous version has been restored."
}
