#!/bin/bash
# scripts/wallpaper_picker.sh
# Rofi-wayland wallpaper picker with previews and theme application
# Requires: rofi-wayland, swww, imagemagick (for thumbnails)

set -euo pipefail

# Configuration
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source centralized logging
source "$DOTFILES_DIR/theme_engine/logger.sh"
log_script_start "$@"
WALLPAPERS_DIR="${DOTFILES_DIR}/wallpapers"
THUMBNAILS_DIR="${WALLPAPERS_DIR}/thumbnails"
THEME_ENGINE_DIR="${DOTFILES_DIR}/theme_engine"
ROFI_THEME="${HOME}/.config/rofi/wallpaper-picker.rasi"

# Colors for rofi (will be themed later)
ROFI_COLORS="window {background-color: #1e1e2e;} listview {background-color: #1e1e2e;} element {text-color: #cdd6f4;}"

# Ensure directories exist
mkdir -p "${THUMBNAILS_DIR}"

# Function to generate thumbnail if it doesn't exist
generate_thumbnail() {
    local wallpaper="$1"
    local thumbnail="${THUMBNAILS_DIR}/$(basename "${wallpaper%.*}.jpg")"
    
    if [[ ! -f "$thumbnail" ]]; then
        echo "Generating thumbnail for $(basename "$wallpaper")..."
        # Create 200x200 thumbnail with imagemagick
        convert "$wallpaper" -resize 200x200^ -gravity center -extent 200x200 "$thumbnail"
    fi
    
    echo "$thumbnail"
}

# Function to get all wallpapers recursively
get_wallpapers() {
    find "$WALLPAPERS_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort
}

# Function to create rofi entry with preview
create_rofi_entry() {
    local wallpaper="$1"
    local thumbnail="$2"
    local basename=$(basename "$wallpaper")
    local dirname=$(basename "$(dirname "$wallpaper")")
    
    # Format: "thumbnail_path|display_name|full_path"
    echo "${thumbnail}|${dirname}/${basename}|${wallpaper}"
}

# Function to show wallpaper picker
show_picker() {
    local wallpapers=()
    local rofi_entries=()
    
    echo "Scanning wallpapers..."
    
    # Generate thumbnails and create rofi entries
    while IFS= read -r wallpaper; do
        if [[ -f "$wallpaper" ]]; then
            local thumbnail=$(generate_thumbnail "$wallpaper")
            local entry=$(create_rofi_entry "$wallpaper" "$thumbnail")
            rofi_entries+=("$entry")
        fi
    done < <(get_wallpapers)
    
    if [[ ${#rofi_entries[@]} -eq 0 ]]; then
        echo "No wallpapers found in $WALLPAPERS_DIR"
        exit 1
    fi
    
    echo "Found ${#rofi_entries[@]} wallpapers"
    
    # Create rofi input with preview support
    local selected
    selected=$(printf '%s\n' "${rofi_entries[@]}" | \
        rofi -dmenu \
             -i \
             -p "Select Wallpaper" \
             -theme "$ROFI_THEME" \
             -markup-rows \
             -format "s" \
             -selected-row 0 \
             -scroll-method 1 \
             -cycle \
             -eh 2 \
             -width 80 \
             -lines 10 \
             -columns 1 \
             -display-columns 2 \
             -separator-style "none" \
             -hide-scrollbar \
             -kb-accept-entry "Return,KP_Enter" \
             -kb-cancel "Escape,Control+c" \
             | cut -d'|' -f3)
    
    if [[ -n "$selected" && -f "$selected" ]]; then
        echo "Selected: $selected"
        return 0
    else
        echo "No wallpaper selected or file not found"
        exit 1
    fi
}

# Function to set wallpaper with swww
set_wallpaper() {
    local wallpaper="$1"
    
    echo "Setting wallpaper: $(basename "$wallpaper")"
    
    # Check if swww daemon is running
    if ! pgrep -x swww-daemon > /dev/null 2>&1; then
        echo "Starting swww daemon..."
        swww-daemon &
        sleep 2
    fi
    
    # Set wallpaper with transition
    swww img "$wallpaper" \
        --transition-type wipe \
        --transition-duration 1 \
        --transition-fps 60 \
        --transition-angle 30
}

# Function to apply theme based on selected wallpaper
apply_theme() {
    local wallpaper="$1"
    
    echo "Applying theme for wallpaper: $(basename "$wallpaper")"
    
    # Call the main theme application script
    if [[ -x "${DOTFILES_DIR}/scripts/apply_theme.sh" ]]; then
        "${DOTFILES_DIR}/scripts/apply_theme.sh" "$wallpaper"
    else
        echo "Theme application script not found or not executable"
        echo "Wallpaper set, but theme not applied"
    fi
}

# Main function
main() {
    echo "Dynamic Wallpaper & Theme Picker"
    echo "================================"
    
    # Check dependencies
    local missing_deps=()
    for cmd in rofi swww convert; do
        if ! command -v "$cmd" > /dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "Missing dependencies: ${missing_deps[*]}"
        echo "Please install: rofi-wayland swww imagemagick"
        exit 1
    fi
    
    # Show wallpaper picker
    local selected_wallpaper
    selected_wallpaper=$(show_picker)
    
    if [[ -n "$selected_wallpaper" ]]; then
        # Set wallpaper
        set_wallpaper "$selected_wallpaper"
        
        # Apply theme
        apply_theme "$selected_wallpaper"
        
        echo "Wallpaper and theme applied successfully!"
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

# Ensure proper exit logging
trap 'log_script_end $?' EXIT