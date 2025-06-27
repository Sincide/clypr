#!/bin/bash
# theme_engine/reload_apps.sh
# Reload/restart applications after theme changes for atomic theming

set -euo pipefail

# Source centralized logging
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"
log_script_start "$@"

# Function to reload Hyprland
reload_hyprland() {
    if command -v hyprctl > /dev/null 2>&1; then
        if hyprctl reload > /dev/null 2>&1; then
            log_success "RELOAD" "Hyprland configuration reloaded"
        else
            log_warning "RELOAD" "Failed to reload Hyprland"
        fi
    else
        log_warning "RELOAD" "Hyprland not running or hyprctl not found"
    fi
}

# Function to restart Waybar
restart_waybar() {
    log_info "RELOAD" "Restarting Waybar..."
    
    # Kill existing waybar processes
    if pgrep -x waybar > /dev/null; then
        pkill waybar
        sleep 1
    fi
    
    # Start new waybar instances
    waybar -c ~/.config/waybar/config-top.json &
    waybar -c ~/.config/waybar/config-bottom.json &
    
    sleep 2
    
    if pgrep -x waybar > /dev/null; then
        log_success "RELOAD" "Waybar restarted successfully"
    else
        log_error "RELOAD" "Failed to restart Waybar"
    fi
}

# Function to reload dunst
reload_dunst() {
    if command -v dunstctl > /dev/null 2>&1; then
        if dunstctl reload > /dev/null 2>&1; then
            print_status "$GREEN" "✓ Dunst configuration reloaded"
        else
            print_status "$YELLOW" "⚠ Failed to reload Dunst"
        fi
    else
        print_status "$YELLOW" "⚠ Dunst not running or dunstctl not found"
    fi
}

# Function to reload terminal applications
reload_terminals() {
    # Terminals will pick up new themes on next launch
    # Send signal to existing terminals to reload config if they support it
    
    # Kitty supports config reload
    if command -v kitty > /dev/null 2>&1; then
        # Send SIGUSR1 to all kitty instances to reload config
        if pgrep -x kitty > /dev/null; then
            pkill -SIGUSR1 kitty
            print_status "$GREEN" "✓ Kitty configurations reloaded"
        fi
    fi
    
    # Foot doesn't support config reload, but new instances will use new theme
    print_status "$GREEN" "✓ Terminal themes will apply to new instances"
}

# Function to update GTK themes
update_gtk_themes() {
    if command -v gsettings > /dev/null 2>&1; then
        # Force GTK applications to refresh themes
        gsettings set org.gnome.desktop.interface gtk-theme "Adwaita"
        sleep 0.5
        gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
        
        print_status "$GREEN" "✓ GTK themes updated"
    else
        print_status "$YELLOW" "⚠ gsettings not found, GTK theme not updated"
    fi
}

# Function to refresh rofi theme
refresh_rofi() {
    # Rofi will use new theme on next launch
    print_status "$GREEN" "✓ Rofi theme will apply on next launch"
}

# Function to notify user about applications that need manual restart
notify_manual_restart() {
    print_status "$YELLOW" "Applications that may need manual restart for full theme:"
    print_status "$YELLOW" "  • Brave/Web browsers"
    print_status "$YELLOW" "  • File managers"
    print_status "$YELLOW" "  • Some GTK applications"
    print_status "$YELLOW" "  • Terminal instances (for immediate effect)"
}

# Function to check if applications are running and need restart
check_running_apps() {
    local apps_to_check=("brave" "brave-browser" "thunar" "nautilus" "code")
    local running_apps=()
    
    for app in "${apps_to_check[@]}"; do
        if pgrep -x "$app" > /dev/null; then
            running_apps+=("$app")
        fi
    done
    
    if [[ ${#running_apps[@]} -gt 0 ]]; then
        print_status "$YELLOW" "Running applications that may benefit from restart:"
        for app in "${running_apps[@]}"; do
            print_status "$YELLOW" "  • $app"
        done
    fi
}

# Function to send desktop notification
send_notification() {
    if command -v notify-send > /dev/null 2>&1; then
        notify-send "Theme Applied" "Dynamic theme has been applied successfully!" \
                   --icon=preferences-desktop-theme \
                   --urgency=normal \
                   --expire-time=3000
    fi
}

# Main reload function
main() {
    print_status "$GREEN" "Reloading applications with new theme..."
    
    # Core window manager and bars
    reload_hyprland
    restart_waybar
    
    # Notification system
    reload_dunst
    
    # Terminal applications
    reload_terminals
    
    # GTK theme system
    update_gtk_themes
    
    # Other applications
    refresh_rofi
    
    # Check for applications that might need manual restart
    check_running_apps
    
    # Show information about manual restarts
    notify_manual_restart
    
    # Send desktop notification
    send_notification
    
    print_status "$GREEN" "Application reload complete!"
}

# Run main function
main "$@"

# Ensure proper exit logging
trap 'log_script_end $?' EXIT