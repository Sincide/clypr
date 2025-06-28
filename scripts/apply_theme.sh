#!/bin/bash
# scripts/apply_theme.sh
# Main theme application script - orchestrates the entire theming workflow
# Usage: apply_theme.sh <wallpaper_path> or apply_theme.sh restore

set -euo pipefail

# Enable debug mode if DEBUG env var is set
if [[ "${DEBUG:-}" == "1" ]]; then
    set -x
fi

# Configuration
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEME_ENGINE_DIR="${DOTFILES_DIR}/theme_engine"
SCRIPTS_DIR="${DOTFILES_DIR}/scripts"

# Source centralized logging
if [[ -f "$DOTFILES_DIR/theme_engine/logger.sh" ]]; then
    source "$DOTFILES_DIR/theme_engine/logger.sh"
    log_script_start "$@"
else
    echo "ERROR: Logger not found at $DOTFILES_DIR/theme_engine/logger.sh"
    exit 1
fi

# Function to print colored output
print_status() {
    local color="$1"
    local message="$2"
    echo -e "${color}[$(date +'%H:%M:%S')] ${message}${NC}"
}

print_success() { print_status "$GREEN" "✓ $1"; }
print_error() { print_status "$RED" "✗ $1"; }
print_warning() { print_status "$YELLOW" "⚠ $1"; }
print_info() { print_status "$BLUE" "ℹ $1"; }

# Function to check dependencies
check_dependencies() {
    print_info "Checking dependencies..."
    
    local missing_deps=()
    local python_deps=("requests" "pathlib")
    
    # Check system dependencies
    for cmd in python3 swww; do
        if ! command -v "$cmd" > /dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Check Python dependencies
    for dep in "${python_deps[@]}"; do
        if ! python3 -c "import $dep" 2>/dev/null; then
            missing_deps+=("python3-$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_info "Install with: sudo pacman -S python3 swww python-requests"
        exit 1
    fi
    
    print_success "All dependencies available"
}

# Function to extract colors from wallpaper
extract_colors() {
    local wallpaper_path="$1"
    
    print_info "Extracting colors from wallpaper..."
    
    if [[ ! -f "$wallpaper_path" ]]; then
        print_error "Wallpaper file not found: $wallpaper_path"
        exit 1
    fi
    
    # Call color extraction engine
    if ! python3 "${THEME_ENGINE_DIR}/extract_colors.py" "$wallpaper_path" > /dev/null; then
        print_error "Color extraction failed"
        exit 1
    fi
    
    print_success "Colors extracted successfully"
}

# Function to render templates
render_templates() {
    print_info "Rendering theme templates..."
    
    # Call template renderer
    if ! python3 "${THEME_ENGINE_DIR}/render_templates.py" > /dev/null; then
        print_error "Template rendering failed"
        exit 1
    fi
    
    print_success "Templates rendered successfully"
}

# Function to merge configs
merge_configs() {
    print_info "Merging configurations..."
    
    # Call config merger
    if ! python3 "${THEME_ENGINE_DIR}/merge_configs.py" > /dev/null; then
        print_error "Config merging failed"
        exit 1
    fi
    
    print_success "Configurations merged successfully"
}

# Function to set wallpaper
set_wallpaper() {
    local wallpaper_path="$1"
    
    print_info "Setting wallpaper..."
    
    # Check if swww daemon is running
    if ! pgrep -x swww-daemon > /dev/null 2>&1; then
        print_info "Starting swww daemon..."
        swww-daemon &
        sleep 2
    fi
    
    # Set wallpaper with transition
    if ! swww img "$wallpaper_path" \
        --transition-type wipe \
        --transition-duration 1 \
        --transition-fps 60 \
        --transition-angle 30; then
        print_error "Failed to set wallpaper"
        exit 1
    fi
    
    print_success "Wallpaper set successfully"
}

# Function to reload applications
reload_applications() {
    print_info "Reloading applications..."
    
    local reload_script="${THEME_ENGINE_DIR}/reload_apps.sh"
    
    if [[ -x "$reload_script" ]]; then
        if ! "$reload_script"; then
            print_warning "Some applications failed to reload"
        else
            print_success "Applications reloaded successfully"
        fi
    else
        print_warning "Application reload script not found or not executable"
        manual_reload
    fi
}

# Function for manual application reload
manual_reload() {
    print_info "Performing manual application reload..."
    
    # Reload Hyprland configuration
    if command -v hyprctl > /dev/null 2>&1; then
        hyprctl reload > /dev/null 2>&1 && print_success "Hyprland reloaded"
    fi
    
    # Restart Waybar
    if pgrep -x waybar > /dev/null; then
        pkill waybar
        sleep 1
        waybar -c ~/.config/waybar/config-left.json &
        waybar -c ~/.config/waybar/config-right.json &
        print_success "Waybar restarted"
    fi
    
    # Reload dunst
    if command -v dunstctl > /dev/null 2>&1; then
        dunstctl reload > /dev/null 2>&1 && print_success "Dunst reloaded"
    fi
    
    # Update GTK theme
    if command -v gsettings > /dev/null 2>&1; then
        # Read current theme from theme data
        local current_theme_file="${THEME_ENGINE_DIR}/theme_data/current.json"
        if [[ -f "$current_theme_file" ]]; then
            local gtk_theme=$(python3 -c "
import json
with open('$current_theme_file', 'r') as f:
    data = json.load(f)
print('Adwaita-dark')  # Default for now
")
            gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
            print_success "GTK theme updated"
        fi
    fi
}

# Function to restore previous theme
restore_theme() {
    print_info "Restoring previous theme..."
    
    local current_theme_file="${THEME_ENGINE_DIR}/theme_data/current.json"
    
    if [[ ! -f "$current_theme_file" ]]; then
        print_error "No previous theme found to restore"
        exit 1
    fi
    
    # Extract wallpaper path from current theme
    local wallpaper_path
    wallpaper_path=$(python3 -c "
import json
with open('$current_theme_file', 'r') as f:
    data = json.load(f)
print(data['wallpaper_path'])
")
    
    if [[ -f "$wallpaper_path" ]]; then
        print_info "Restoring theme for wallpaper: $(basename "$wallpaper_path")"
        
        # Re-render templates and merge configs
        render_templates
        merge_configs
        set_wallpaper "$wallpaper_path"
        reload_applications
        
        print_success "Theme restored successfully"
    else
        print_error "Previous wallpaper not found: $wallpaper_path"
        exit 1
    fi
}

# Function to display usage
usage() {
    echo "Usage: $0 <wallpaper_path|restore>"
    echo ""
    echo "Commands:"
    echo "  apply_theme.sh /path/to/wallpaper.jpg  - Apply theme based on wallpaper"
    echo "  apply_theme.sh restore                 - Restore previous theme"
    echo ""
    echo "The script will:"
    echo "  1. Extract colors from wallpaper using LLaVA/Ollama"
    echo "  2. Render theme templates with extracted colors"
    echo "  3. Merge templates with static configurations"
    echo "  4. Set wallpaper with smooth transition"
    echo "  5. Reload all themed applications atomically"
    exit 1
}

# Function to create backup
create_backup() {
    local backup_dir="${THEME_ENGINE_DIR}/theme_data/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup current theme data
    if [[ -f "${THEME_ENGINE_DIR}/theme_data/current.json" ]]; then
        cp "${THEME_ENGINE_DIR}/theme_data/current.json" "$backup_dir/"
    fi
    
    print_info "Backup created at $backup_dir"
}

# Main function
main() {
    echo "Dynamic Theme Application System"
    echo "==============================="
    
    # Parse arguments
    if [[ $# -eq 0 ]]; then
        usage
    fi
    
    local action="$1"
    
    # Check dependencies
    check_dependencies
    
    # Create backup
    create_backup
    
    case "$action" in
        "restore")
            restore_theme
            ;;
        *)
            # Treat as wallpaper path
            local wallpaper_path="$action"
            
            if [[ ! -f "$wallpaper_path" ]]; then
                print_error "Wallpaper file not found: $wallpaper_path"
                exit 1
            fi
            
            # Full theme application workflow
            print_info "Applying theme for wallpaper: $(basename "$wallpaper_path")"
            
            extract_colors "$wallpaper_path"
            render_templates
            merge_configs
            set_wallpaper "$wallpaper_path"
            reload_applications
            
            print_success "Theme applied successfully!"
            print_info "Wallpaper: $(basename "$wallpaper_path")"
            
            # Show color palette
            local current_theme_file="${THEME_ENGINE_DIR}/theme_data/current.json"
            if [[ -f "$current_theme_file" ]]; then
                print_info "Color palette:"
                python3 -c "
import json
with open('$current_theme_file', 'r') as f:
    data = json.load(f)
palette = data['palette']
for key, color in palette.items():
    print(f'  {key}: {color}')
"
            fi
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

# Ensure proper exit logging
trap 'log_script_end $?' EXIT