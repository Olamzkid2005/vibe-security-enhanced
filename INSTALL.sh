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

# Validation: Check if source directory exists
if [ ! -d "vibe-security-enhanced" ]; then
    echo "ERROR: Source directory 'vibe-security-enhanced' not found!"
    echo "Please run this script from the directory containing the vibe-security-enhanced folder."
    exit 1
fi

# Validation: Check if required files exist
REQUIRED_FILES=(
    "vibe-security-enhanced/skill.md"
    "vibe-security-enhanced/README.md"
    "vibe-security-enhanced/references/secrets-and-env.md"
    "vibe-security-enhanced/references/authentication.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "ERROR: Required file '$file' not found!"
        echo "Installation package may be incomplete."
        exit 1
    fi
done

echo "✓ Source files validated"
echo ""

# Function to check if destination already exists
check_existing_installation() {
    local install_dir=$1
    
    if [ -d "$install_dir/vibe-security-enhanced" ]; then
        echo ""
        echo "WARNING: Installation already exists at:"
        echo "  $install_dir/vibe-security-enhanced"
        echo ""
        read -p "Overwrite existing installation? [y/N]: " confirm
        
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            return 1
        fi
        
        echo "Removing existing installation..."
        rm -rf "$install_dir/vibe-security-enhanced"
    fi
    
    return 0
}

# Function to install for a specific assistant
install_for_assistant() {
    local assistant=$1
    local install_dir=$2
    
    echo "Installing for $assistant..."
    
    # Check for existing installation
    if ! check_existing_installation "$install_dir"; then
        return 1
    fi
    
    # Create directory if it doesn't exist
    mkdir -p "$install_dir"
    
    # Copy skill files
    cp -r vibe-security-enhanced "$install_dir/"
    
    # Verify installation
    if [ -f "$install_dir/vibe-security-enhanced/skill.md" ]; then
        echo "✓ Installed to: $install_dir/vibe-security-enhanced"
        return 0
    else
        echo "✗ Installation verification failed!"
        return 1
    fi
}

# Function to validate project path
validate_project_path() {
    local path=$1
    
    if [ -z "$path" ]; then
        echo "ERROR: Project path cannot be empty"
        return 1
    fi
    
    if [ ! -d "$path" ]; then
        echo "ERROR: Project path does not exist: $path"
        read -p "Create directory? [y/N]: " create_dir
        
        if [[ "$create_dir" =~ ^[Yy]$ ]]; then
            mkdir -p "$path"
            echo "✓ Created directory: $path"
        else
            return 1
        fi
    fi
    
    return 0
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

INSTALL_SUCCESS=true

case $choice in
    1)
        install_for_assistant "Kiro (user-level)" "$HOME_DIR/.kiro/skills" || INSTALL_SUCCESS=false
        ;;
    2)
        read -p "Enter project path: " project_path
        if validate_project_path "$project_path"; then
            install_for_assistant "Kiro (project-level)" "$project_path/.kiro/skills" || INSTALL_SUCCESS=false
        else
            INSTALL_SUCCESS=false
        fi
        ;;
    3)
        install_for_assistant "Claude Code (user-level)" "$HOME_DIR/.claude/skills" || INSTALL_SUCCESS=false
        ;;
    4)
        read -p "Enter project path: " project_path
        if validate_project_path "$project_path"; then
            install_for_assistant "Claude Code (project-level)" "$project_path/.claude/skills" || INSTALL_SUCCESS=false
        else
            INSTALL_SUCCESS=false
        fi
        ;;
    5)
        install_for_assistant "Cursor (user-level)" "$HOME_DIR/.cursor/skills" || INSTALL_SUCCESS=false
        ;;
    6)
        read -p "Enter custom installation path: " custom_path
        if validate_project_path "$custom_path"; then
            install_for_assistant "Custom" "$custom_path" || INSTALL_SUCCESS=false
        else
            INSTALL_SUCCESS=false
        fi
        ;;
    7)
        echo "Installing for all assistants..."
        echo ""
        install_for_assistant "Kiro" "$HOME_DIR/.kiro/skills" || INSTALL_SUCCESS=false
        echo ""
        install_for_assistant "Claude Code" "$HOME_DIR/.claude/skills" || INSTALL_SUCCESS=false
        echo ""
        install_for_assistant "Cursor" "$HOME_DIR/.cursor/skills" || INSTALL_SUCCESS=false
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""

if [ "$INSTALL_SUCCESS" = true ]; then
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
else
    echo "==================================="
    echo "Installation Failed or Cancelled"
    echo "==================================="
    echo ""
    echo "Some installations may have failed."
    echo "Please check the error messages above."
    exit 1
fi
