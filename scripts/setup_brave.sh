#!/bin/bash
# setup_brave.sh
# Setup Brave browser with backup/restore integration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGGER_PATH="${SCRIPT_DIR}/../theme_engine/logger.sh"

# Source centralized logger
if [[ -f "$LOGGER_PATH" ]]; then
    source "$LOGGER_PATH"
else
    echo "Error: Logger not found at $LOGGER_PATH"
    exit 1
fi

log_script_start "$@"

# Function to check if Brave is installed
check_brave_installed() {
    if command -v brave > /dev/null 2>&1; then
        log_success "BRAVE" "Brave browser is installed"
        return 0
    elif command -v brave-browser > /dev/null 2>&1; then
        log_success "BRAVE" "Brave browser is installed (brave-browser)"
        return 0
    else
        log_error "BRAVE" "Brave browser is not installed"
        log_info "BRAVE" "Install with: yay -S brave-bin"
        return 1
    fi
}

# Function to create backup directories
setup_backup_dirs() {
    local backup_dir="${SCRIPT_DIR}/../backups/brave"
    
    log_info "BRAVE" "Creating backup directories..."
    mkdir -p "$backup_dir"
    
    if [[ -d "$backup_dir" ]]; then
        log_success "BRAVE" "Backup directory created: $backup_dir"
    else
        log_error "BRAVE" "Failed to create backup directory"
        return 1
    fi
}

# Function to make backup script accessible
setup_brave_backup_command() {
    local backup_script="${SCRIPT_DIR}/brave_backup.sh"
    local bin_dir="$HOME/.local/bin"
    local link_path="$bin_dir/brave-backup"
    
    log_info "BRAVE" "Setting up brave-backup command..."
    
    # Create bin directory if it doesn't exist
    mkdir -p "$bin_dir"
    
    # Create symlink to backup script
    if [[ -L "$link_path" ]]; then
        rm "$link_path"
    fi
    
    ln -s "$backup_script" "$link_path"
    
    if [[ -L "$link_path" && -x "$link_path" ]]; then
        log_success "BRAVE" "brave-backup command available in PATH"
        log_info "BRAVE" "Use 'brave-backup' to backup/restore Brave data"
    else
        log_error "BRAVE" "Failed to setup brave-backup command"
        return 1
    fi
}

# Function to show usage information
show_brave_info() {
    log_info "BRAVE" "═══ Brave Browser Integration ═══"
    echo
    echo "Available commands:"
    echo "  brave-backup menu          - Interactive backup/restore menu"
    echo "  brave-backup backup        - Create backup of current Brave data"
    echo "  brave-backup restore       - Restore from available backups"
    echo "  brave-backup list          - List available backups"
    echo
    echo "Keyboard shortcuts:"
    echo "  Super+W                    - Open Brave browser"
    echo "  Super+Shift+B              - Open Brave backup tool"
    echo
    echo "Backup locations:"
    echo "  - ~/clypr/backups/brave/   - Local clypr backups"
    echo "  - External drives          - Auto-detected mounted drives"
    echo
    echo "The Brave backup system integrates with the clypr logging system"
    echo "and supports both local and external drive backups."
}

# Main function
main() {
    log_info "BRAVE" "Setting up Brave browser integration..."
    
    # Check if Brave is installed
    if ! check_brave_installed; then
        log_warning "BRAVE" "Brave browser not found - setup incomplete"
        log_info "BRAVE" "Install Brave first, then run this script again"
        return 1
    fi
    
    # Setup backup directories
    setup_backup_dirs
    
    # Setup command line tool
    setup_brave_backup_command
    
    # Show information
    show_brave_info
    
    log_success "BRAVE" "Brave browser integration setup complete!"
}

# Run main function
main "$@"

# Ensure proper exit logging
trap 'log_script_end $?' EXIT