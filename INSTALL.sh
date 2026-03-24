#!/bin/bash

# Vibe Security Enhanced - Installation Script
# This script installs the security skill for various AI assistants

set -e

echo "==================================="
echo "Vibe Security Enhanced Installer"
echo "Version 2.0"
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
    
    # Copy skill files
    cp -r vibe-security-enhanced "$install_dir/"
    
    echo "✓ Installed to: $install_dir/vibe-security-enhanced"
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
        install_for_assistant "Kiro (user-level)" "$HOME_DIR/.kiro/skills"
        ;;
    2)
        read -p "Enter project path: " project_path
        install_for_assistant "Kiro (project-level)" "$project_path/.kiro/skills"
        ;;
    3)
        install_for_assistant "Claude Code (user-level)" "$HOME_DIR/.claude/skills"
        ;;
    4)
        read -p "Enter project path: " project_path
        install_for_assistant "Claude Code (project-level)" "$project_path/.claude/skills"
        ;;
    5)
        install_for_assistant "Cursor (user-level)" "$HOME_DIR/.cursor/skills"
        ;;
    6)
        read -p "Enter custom installation path: " custom_path
        install_for_assistant "Custom" "$custom_path"
        ;;
    7)
        install_for_assistant "Kiro" "$HOME_DIR/.kiro/skills"
        install_for_assistant "Claude Code" "$HOME_DIR/.claude/skills"
        install_for_assistant "Cursor" "$HOME_DIR/.cursor/skills"
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
echo "The skill will automatically activate when you:"
echo "- Ask about security"
echo "- Request code reviews"
echo "- Work with authentication, payments, or sensitive data"
echo ""
echo "For manual activation:"
echo "- Kiro/Claude: Ask 'run a security audit'"
echo "- Claude Code: Use /vibe-security-enhanced"
echo ""
echo "See README.md for full documentation."
