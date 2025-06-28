#!/bin/bash
# scripts/wallpaper_picker.sh
# Rofi-wayland wallpaper picker with previews and theme application
# Requires: rofi-wayland, swww, imagemagick (for thumbnails)

set -euo pipefail

# Enable debug mode if DEBUG env var is set
if [[ "${DEBUG:-}" == "1" ]]; then
    set -x
fi

# Configuration
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source centralized logging
if [[ -f "$DOTFILES_DIR/theme_engine/logger.sh" ]]; then
    source "$DOTFILES_DIR/theme_engine/logger.sh"
    log_script_start "$@"
else
    echo "ERROR: Logger not found at $DOTFILES_DIR/theme_engine/logger.sh"
    exit 1
fi
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
    
    log_debug "WALLPAPER" "Checking thumbnail for: $(basename "$wallpaper")"
    log_debug "WALLPAPER" "Thumbnail path: $thumbnail"
    
    if [[ ! -f "$thumbnail" ]]; then
        log_info "WALLPAPER" "Generating thumbnail for $(basename "$wallpaper")..."
        # Create 200x200 thumbnail with imagemagick
        if convert "$wallpaper" -resize 200x200^ -gravity center -extent 200x200 "$thumbnail" 2>/dev/null; then
            log_success "WALLPAPER" "Thumbnail generated: $thumbnail"
        else
            log_error "WALLPAPER" "Failed to generate thumbnail for $wallpaper"
            return 1
        fi
    else
        log_debug "WALLPAPER" "Thumbnail already exists: $thumbnail"
    fi
    
    echo "$thumbnail"
}

# Function to get all wallpapers recursively
get_wallpapers() {
    log_info "WALLPAPER" "Scanning for wallpapers in: $WALLPAPERS_DIR"
    
    if [[ ! -d "$WALLPAPERS_DIR" ]]; then
        log_error "WALLPAPER" "Wallpapers directory does not exist: $WALLPAPERS_DIR"
        return 1
    fi
    
    local wallpapers
    wallpapers=$(find "$WALLPAPERS_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | sort)
    
    local count=$(echo "$wallpapers" | wc -l)
    if [[ -z "$wallpapers" ]]; then
        count=0
    fi
    
    log_info "WALLPAPER" "Found $count wallpaper files"
    
    if [[ $count -eq 0 ]]; then
        log_warning "WALLPAPER" "No wallpapers found. Add wallpapers to $WALLPAPERS_DIR"
        return 1
    fi
    
    echo "$wallpapers"
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
    
    log_info "WALLPAPER" "Starting wallpaper picker..."
    
    # Get wallpapers - this function now includes error checking
    local wallpaper_list
    if ! wallpaper_list=$(get_wallpapers); then
        log_error "WALLPAPER" "Failed to get wallpapers"
        return 1
    fi
    
    # Generate thumbnails and create rofi entries
    while IFS= read -r wallpaper; do
        if [[ -n "$wallpaper" && -f "$wallpaper" ]]; then
            log_debug "WALLPAPER" "Processing wallpaper: $wallpaper"
            local thumbnail
            if thumbnail=$(generate_thumbnail "$wallpaper"); then
                local entry=$(create_rofi_entry "$wallpaper" "$thumbnail")
                rofi_entries+=("$entry")
                log_debug "WALLPAPER" "Added entry: $entry"
            else
                log_warning "WALLPAPER" "Skipping wallpaper (thumbnail failed): $wallpaper"
            fi
        fi
    done <<< "$wallpaper_list"
    
    if [[ ${#rofi_entries[@]} -eq 0 ]]; then
        log_error "WALLPAPER" "No valid wallpapers found in $WALLPAPERS_DIR"
        return 1
    fi
    
    log_success "WALLPAPER" "Prepared ${#rofi_entries[@]} wallpapers for picker"
    
    # Check if rofi theme exists, fallback to simple rofi if not
    local rofi_args=()
    if [[ -f "$ROFI_THEME" ]]; then
        log_info "WALLPAPER" "Using rofi theme: $ROFI_THEME"
        rofi_args+=("-theme" "$ROFI_THEME")
    else
        log_warning "WALLPAPER" "Rofi theme not found: $ROFI_THEME, using default"
    fi
    
    # Create rofi input with preview support
    log_info "WALLPAPER" "Launching rofi with ${#rofi_entries[@]} entries..."
    
    local selected
    selected=$(printf '%s\n' "${rofi_entries[@]}" | \
        rofi -dmenu \
             -i \
             -p "Select Wallpaper" \
             "${rofi_args[@]}" \
             -format "s" \
             -selected-row 0 \
             -lines 10 \
             -columns 1 \
             -separator-style "none" \
             -hide-scrollbar \
             2>&1 | cut -d'|' -f3)
    
    local rofi_exit_code=${PIPESTATUS[1]}
    log_debug "WALLPAPER" "Rofi exit code: $rofi_exit_code"
    
    if [[ $rofi_exit_code -eq 0 && -n "$selected" && -f "$selected" ]]; then
        log_success "WALLPAPER" "Selected wallpaper: $selected"
        echo "$selected"
        return 0
    elif [[ $rofi_exit_code -eq 1 ]]; then
        log_info "WALLPAPER" "User cancelled selection"
        return 1
    else
        log_error "WALLPAPER" "Rofi failed with exit code: $rofi_exit_code"
        log_error "WALLPAPER" "Selected value: '$selected'"
        return 1
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
    log_info "WALLPAPER" "=== Dynamic Wallpaper & Theme Picker ==="
    log_info "WALLPAPER" "Dotfiles directory: $DOTFILES_DIR"
    log_info "WALLPAPER" "Wallpapers directory: $WALLPAPERS_DIR"
    
    # Check dependencies
    log_info "WALLPAPER" "Checking dependencies..."
    local missing_deps=()
    local deps=(rofi swww convert)
    
    for cmd in "${deps[@]}"; do
        if command -v "$cmd" > /dev/null 2>&1; then
            log_success "WALLPAPER" "Found dependency: $cmd"
        else
            missing_deps+=("$cmd")
            log_error "WALLPAPER" "Missing dependency: $cmd"
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "WALLPAPER" "Missing dependencies: ${missing_deps[*]}"
        log_info "WALLPAPER" "Please install: rofi-wayland swww imagemagick"
        return 1
    fi
    
    # Ensure directories exist
    log_info "WALLPAPER" "Creating directories..."
    mkdir -p "$WALLPAPERS_DIR"
    mkdir -p "$THUMBNAILS_DIR"
    
    # Show wallpaper picker
    log_info "WALLPAPER" "Starting wallpaper selection..."
    local selected_wallpaper
    if selected_wallpaper=$(show_picker); then
        log_success "WALLPAPER" "Wallpaper selected: $selected_wallpaper"
        
        # Set wallpaper
        log_info "WALLPAPER" "Setting wallpaper..."
        if set_wallpaper "$selected_wallpaper"; then
            log_success "WALLPAPER" "Wallpaper set successfully"
            
            # Apply theme
            log_info "WALLPAPER" "Applying theme..."
            if apply_theme "$selected_wallpaper"; then
                log_success "WALLPAPER" "Theme applied successfully"
                log_success "WALLPAPER" "Wallpaper and theme applied successfully!"
            else
                log_warning "WALLPAPER" "Wallpaper set but theme application failed"
            fi
        else
            log_error "WALLPAPER" "Failed to set wallpaper"
            return 1
        fi
    else
        log_info "WALLPAPER" "No wallpaper selected or selection failed"
        return 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

# Ensure proper exit logging
trap 'log_script_end $?' EXIT