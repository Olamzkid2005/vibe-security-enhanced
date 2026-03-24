#!/bin/bash

# Superpowers Skills Framework - Installation Script
# This script installs the skills framework for various AI assistants

set -e

echo "==================================="
echo "Superpowers Skills Framework Installer"
echo "Version 1.0"
echo "==================================="
echo ""

# Detect OS
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    IS_WINDOWS=true
    HOME_DIR="$USERPROFILE"
else
    IS_WINDOWS=false
    HOME_DIR="$HOME"
fi

# Function to install for a specific assistant
install_for_assistant() {
    local assistant=$1
    local install_dir=$2
    
    echo "Installing for $assistant..."
    
    # Create directory if it doesn't exist
    mkdir -p "$install_dir"
    
    # Copy steering files
    cp -r steering/* "$install_dir/"
    
    echo "✓ Installed to: $install_dir"
}

# Main menu
echo "Select installation type:"
echo "1) Kiro (user-level)"
echo "2) Kiro (project-level)"
echo "3) Claude Code (user-level)"
echo "4) Claude Code (project-level)"
echo "5) Cursor (user-level)"
echo "6) Custom path"
echo "7) Install for all (Kiro, Claude, Cursor)"
echo ""
read -p "Enter choice [1-7]: " choice

case $choice in
    1)
        install_for_assistant "Kiro (user-level)" "$HOME_DIR/.kiro/steering"
        ;;
    2)
        read -p "Enter project path: " project_path
        install_for_assistant "Kiro (project-level)" "$project_path/.kiro/steering"
        ;;
    3)
        install_for_assistant "Claude Code (user-level)" "$HOME_DIR/.claude/steering"
        ;;
    4)
        read -p "Enter project path: " project_path
        install_for_assistant "Claude Code (project-level)" "$project_path/.claude/steering"
        ;;
    5)
        install_for_assistant "Cursor (user-level)" "$HOME_DIR/.cursor/steering"
        ;;
    6)
        read -p "Enter custom installation path: " custom_path
        install_for_assistant "Custom" "$custom_path"
        ;;
    7)
        install_for_assistant "Kiro" "$HOME_DIR/.kiro/steering"
        install_for_assistant "Claude Code" "$HOME_DIR/.claude/steering"
        install_for_assistant "Cursor" "$HOME_DIR/.cursor/steering"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "==================================="
echo "Installation Complete!"
echo "==================================="
echo ""
echo "The skills will automatically guide development:"
echo "- Design before implementation (brainstorming)"
echo "- Test-driven development (TDD)"
echo "- Systematic debugging (root cause analysis)"
echo "- Evidence-based verification"
echo "- Detailed planning"
echo "- Code review checklists"
echo ""
echo "Skills activate automatically based on context."
echo "See README.md for full documentation."
