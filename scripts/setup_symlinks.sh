#!/bin/bash
# scripts/setup_symlinks.sh
# GNU Stow-based symlink management for dotfiles
# Creates symlinks from dotfiles to ~/.config and home directory

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    local color="$1"
    local message="$2"
    echo -e "${color}[SYMLINK] ${message}${NC}"
}

# Function to check if stow is available
check_stow() {
    if ! command -v stow > /dev/null 2>&1; then
        print_status "$RED" "GNU Stow not found. Installing..."
        
        if command -v pacman > /dev/null 2>&1; then
            sudo pacman -S --needed stow
        elif command -v apt > /dev/null 2>&1; then
            sudo apt install stow
        else
            print_status "$RED" "Please install GNU Stow manually"
            exit 1
        fi
    fi
    
    print_status "$GREEN" "GNU Stow available"
}

# Function to backup existing configs
backup_existing_configs() {
    print_status "$BLUE" "Checking for existing configurations..."
    
    local apps=("hypr" "waybar" "rofi" "dunst" "kitty" "foot" "fish" "btop")
    local backup_needed=false
    
    for app in "${apps[@]}"; do
        if [[ -d "$CONFIG_DIR/$app" && ! -L "$CONFIG_DIR/$app" ]]; then
            backup_needed=true
            break
        fi
    done
    
    if [[ "$backup_needed" == "true" ]]; then
        print_status "$YELLOW" "Backing up existing configurations to $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        
        for app in "${apps[@]}"; do
            if [[ -d "$CONFIG_DIR/$app" && ! -L "$CONFIG_DIR/$app" ]]; then
                mv "$CONFIG_DIR/$app" "$BACKUP_DIR/"
                print_status "$BLUE" "Backed up $app config"
            fi
        done
    else
        print_status "$GREEN" "No existing configurations to backup"
    fi
}

# Function to create config package structure for stow
setup_stow_structure() {
    print_status "$BLUE" "Setting up stow package structure..."
    
    local stow_dir="$DOTFILES_DIR/stow_packages"
    
    # Remove old stow structure
    [[ -d "$stow_dir" ]] && rm -rf "$stow_dir"
    
    # Create stow package directory
    mkdir -p "$stow_dir/dotfiles/.config"
    
    # Copy static configs to stow structure
    if [[ -d "$DOTFILES_DIR/config_static" ]]; then
        cp -r "$DOTFILES_DIR/config_static"/* "$stow_dir/dotfiles/.config/"
    fi
    
    # GTK configs go to home directory
    if [[ -d "$DOTFILES_DIR/config_static/gtk" ]]; then
        mkdir -p "$stow_dir/dotfiles"
        
        # GTK2 config
        if [[ -f "$DOTFILES_DIR/config_static/gtk/gtkrc-2.0" ]]; then
            cp "$DOTFILES_DIR/config_static/gtk/gtkrc-2.0" "$stow_dir/dotfiles/.gtkrc-2.0"
        fi
        
        # GTK3/4 configs are handled in .config/gtk-3.0 and .config/gtk-4.0
        mkdir -p "$stow_dir/dotfiles/.config/gtk-3.0"
        mkdir -p "$stow_dir/dotfiles/.config/gtk-4.0"
        
        if [[ -f "$DOTFILES_DIR/config_static/gtk/settings.ini" ]]; then
            cp "$DOTFILES_DIR/config_static/gtk/settings.ini" "$stow_dir/dotfiles/.config/gtk-3.0/"
            cp "$DOTFILES_DIR/config_static/gtk/settings.ini" "$stow_dir/dotfiles/.config/gtk-4.0/"
        fi
    fi
    
    print_status "$GREEN" "Stow structure created"
}

# Function to apply symlinks using stow
apply_symlinks() {
    print_status "$BLUE" "Applying symlinks with GNU Stow..."
    
    local stow_dir="$DOTFILES_DIR/stow_packages"
    
    cd "$HOME"
    
    # Apply dotfiles package
    if ! stow -d "$stow_dir" -t "$HOME" dotfiles; then
        print_status "$RED" "Failed to apply symlinks with stow"
        exit 1
    fi
    
    print_status "$GREEN" "Symlinks applied successfully"
}

# Function to verify symlinks
verify_symlinks() {
    print_status "$BLUE" "Verifying symlinks..."
    
    local apps=("hypr" "waybar" "rofi" "dunst" "kitty" "foot" "fish" "btop")
    local all_good=true
    
    for app in "${apps[@]}"; do
        if [[ -L "$CONFIG_DIR/$app" ]]; then
            print_status "$GREEN" "$app: Symlinked correctly"
        elif [[ -d "$CONFIG_DIR/$app" ]]; then
            print_status "$YELLOW" "$app: Directory exists but not symlinked"
            all_good=false
        else
            print_status "$RED" "$app: Missing"
            all_good=false
        fi
    done
    
    if [[ "$all_good" == "true" ]]; then
        print_status "$GREEN" "All symlinks verified successfully"
    else
        print_status "$YELLOW" "Some symlinks may need attention"
    fi
}

# Function to remove symlinks
remove_symlinks() {
    print_status "$BLUE" "Removing dotfiles symlinks..."
    
    local stow_dir="$DOTFILES_DIR/stow_packages"
    
    cd "$HOME"
    
    if [[ -d "$stow_dir" ]]; then
        stow -d "$stow_dir" -t "$HOME" -D dotfiles
        print_status "$GREEN" "Symlinks removed"
    else
        print_status "$YELLOW" "No stow package found to remove"
    fi
}

# Function to show current symlink status
show_status() {
    print_status "$BLUE" "Current symlink status:"
    
    local apps=("hypr" "waybar" "rofi" "dunst" "kitty" "foot" "fish" "btop")
    
    for app in "${apps[@]}"; do
        if [[ -L "$CONFIG_DIR/$app" ]]; then
            local target=$(readlink "$CONFIG_DIR/$app")
            print_status "$GREEN" "$app -> $target"
        elif [[ -d "$CONFIG_DIR/$app" ]]; then
            print_status "$YELLOW" "$app (directory, not symlinked)"
        else
            print_status "$RED" "$app (missing)"
        fi
    done
}

# Function to display usage
usage() {
    echo "Usage: $0 [install|remove|status|verify]"
    echo ""
    echo "Commands:"
    echo "  install  - Create symlinks for all dotfiles"
    echo "  remove   - Remove symlinks (restore to backed up configs)"
    echo "  status   - Show current symlink status"
    echo "  verify   - Verify symlinks are working correctly"
    echo ""
    echo "The install command will:"
    echo "  1. Backup existing configurations"
    echo "  2. Create stow package structure"
    echo "  3. Apply symlinks using GNU Stow"
    echo "  4. Verify symlinks are working"
    exit 1
}

# Main function
main() {
    case "${1:-install}" in
        "install")
            check_stow
            backup_existing_configs
            setup_stow_structure
            apply_symlinks
            verify_symlinks
            print_status "$GREEN" "Dotfiles symlinks installed successfully!"
            print_status "$BLUE" "You can now run: ${DOTFILES_DIR}/scripts/apply_theme.sh restore"
            ;;
        "remove")
            check_stow
            remove_symlinks
            print_status "$GREEN" "Symlinks removed"
            ;;
        "status")
            show_status
            ;;
        "verify")
            verify_symlinks
            ;;
        *)
            usage
            ;;
    esac
}

# Run main function
main "$@"