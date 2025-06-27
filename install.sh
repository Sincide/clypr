#!/bin/bash
# install.sh
# Installation script for Dynamic Theming Dotfiles
# Designed for Arch Linux with AMDGPU support

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source centralized logging
source "$SCRIPT_DIR/theme_engine/logger.sh"

# Start logging
log_script_start "$@"

print_header() {
    echo -e "${BOLD}${BLUE}"
    echo "=================================================="
    echo "  Dynamic Theming Dotfiles Installation"
    echo "  Arch Linux + Hyprland + AMDGPU"
    echo "=================================================="
    echo -e "${NC}"
    log_info "INSTALL" "Installation started"
    show_log_info
}

# Function to check if running on Arch Linux
check_arch_linux() {
    if [[ ! -f /etc/arch-release ]]; then
        log_error "INSTALL" "This installation script is designed for Arch Linux"
        log_info "INSTALL" "You may need to adapt package names for your distribution"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "INSTALL" "Installation cancelled by user"
            exit 1
        fi
        log_warning "INSTALL" "Continuing on non-Arch system"
    else
        log_success "INSTALL" "Arch Linux detected"
    fi
}

# Function to check for AMDGPU
check_amdgpu() {
    if lspci | grep -i amd > /dev/null; then
        log_success "INSTALL" "AMD GPU detected"
    else
        log_warning "INSTALL" "AMD GPU not detected - AMDGPU optimizations may not work"
        log_info "INSTALL" "System will still work but LLaVA performance may be limited"
    fi
}

# Function to install yay-bin for AUR packages
install_yay() {
    if command -v yay > /dev/null 2>&1; then
        log_success "INSTALL" "yay already installed"
        return 0
    fi
    
    log_info "INSTALL" "Installing yay-bin from AUR..."
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Clone yay-bin
    if ! git clone https://aur.archlinux.org/yay-bin.git; then
        log_error "INSTALL" "Failed to clone yay-bin repository"
        rm -rf "$temp_dir"
        return 1
    fi
    
    cd yay-bin
    
    # Build and install
    log_command "INSTALL" "makepkg -si --noconfirm" "Building yay-bin"
    if makepkg -si --noconfirm; then
        log_success "INSTALL" "yay-bin installed successfully"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 0
    else
        log_error "INSTALL" "Failed to build/install yay-bin"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
}

# Function to install system packages
install_packages() {
    log_info "INSTALL" "Installing required packages..."
    
    # First install base-devel if not present (needed for yay)
    local base_packages=("base-devel" "git")
    local missing_base=()
    
    for package in "${base_packages[@]}"; do
        if ! pacman -Qi "$package" > /dev/null 2>&1; then
            missing_base+=("$package")
        fi
    done
    
    if [[ ${#missing_base[@]} -gt 0 ]]; then
        log_info "INSTALL" "Installing base development packages: ${missing_base[*]}"
        log_command "INSTALL" "sudo pacman -S --needed ${missing_base[*]}"
        if ! sudo pacman -S --needed "${missing_base[@]}"; then
            log_error "INSTALL" "Failed to install base packages"
            return 1
        fi
    fi
    
    # Install yay-bin for AUR access
    install_yay
    
    local packages=(
        # Core desktop
        "hyprland" "waybar" "rofi-wayland" "swww" "dunst"
        
        # Terminals and shell
        "kitty" "foot" "fish"
        
        # System utilities
        "btop" "stow" "imagemagick" "curl" "wget"
        
        # Development tools
        "python" "python-requests" "python-pillow"
        
        # Fonts and themes
        "ttf-jetbrains-mono" "ttf-font-awesome" "papirus-icon-theme"
        
        # Audio and media
        "pipewire" "pipewire-pulse" "wireplumber" "pavucontrol"
        
        # Graphics and screenshot
        "grim" "slurp" "wl-clipboard"
        
        # ROCm for AMDGPU (optional)
        "rocm-hip-runtime" "rocm-opencl-runtime"
    )
    
    local missing_packages=()
    
    log_debug "INSTALL" "Checking package installation status..."
    
    # Check which packages are missing
    for package in "${packages[@]}"; do
        if ! pacman -Qi "$package" > /dev/null 2>&1; then
            missing_packages+=("$package")
            log_debug "INSTALL" "Package $package is missing"
        else
            log_debug "INSTALL" "Package $package is already installed"
        fi
    done
    
    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        log_info "INSTALL" "Installing missing packages: ${missing_packages[*]}"
        log_command "INSTALL" "sudo pacman -S --needed ${missing_packages[*]}"
        
        if sudo pacman -S --needed "${missing_packages[@]}"; then
            log_success "INSTALL" "All packages installed successfully"
        else
            log_error "INSTALL" "Failed to install some packages"
            log_info "INSTALL" "You may need to install them manually"
            return 1
        fi
    else
        log_success "INSTALL" "All required packages already installed"
    fi
    
    # Verify critical packages
    local critical_packages=("hyprland" "waybar" "python")
    for package in "${critical_packages[@]}"; do
        if ! pacman -Qi "$package" > /dev/null 2>&1; then
            log_error "INSTALL" "Critical package $package is missing"
            return 1
        fi
    done
    
    log_success "INSTALL" "Package installation completed"
}

# Function to setup Ollama and LLaVA
setup_ollama() {
    log_info "INSTALL" "Setting up Ollama and LLaVA..."
    
    # Install Ollama if not present
    if ! command -v ollama > /dev/null 2>&1; then
        log_info "INSTALL" "Installing Ollama..."
        curl -fsSL https://ollama.com/install.sh | sh
    else
        log_success "INSTALL" "Ollama already installed"
    fi
    
    # Setup AMDGPU environment for Ollama
    log_info "INSTALL" "Configuring Ollama for AMDGPU..."
    
    # Check if ollama is installed as system or user service
    if systemctl list-unit-files ollama.service > /dev/null 2>&1; then
        # System service exists
        log_info "INSTALL" "Configuring Ollama system service for AMDGPU..."
        
        # Create system service override
        sudo mkdir -p /etc/systemd/system/ollama.service.d
        sudo tee /etc/systemd/system/ollama.service.d/amdgpu.conf > /dev/null << EOF
[Service]
Environment="HSA_OVERRIDE_GFX_VERSION=10.3.0"
Environment="ROCM_PATH=/opt/rocm"
Environment="HIP_VISIBLE_DEVICES=0"
EOF
        
        # Reload and restart system service
        sudo systemctl daemon-reload
        sudo systemctl enable ollama.service
        sudo systemctl restart ollama.service
        
    elif systemctl --user list-unit-files ollama.service > /dev/null 2>&1; then
        # User service exists
        log_info "INSTALL" "Configuring Ollama user service for AMDGPU..."
        
        # Create user service override
        local ollama_override_dir="$HOME/.config/systemd/user/ollama.service.d"
        mkdir -p "$ollama_override_dir"
        
        cat > "$ollama_override_dir/amdgpu.conf" << EOF
[Service]
Environment="HSA_OVERRIDE_GFX_VERSION=10.3.0"
Environment="ROCM_PATH=/opt/rocm"
Environment="HIP_VISIBLE_DEVICES=0"
EOF
        
        # Reload and start user service
        systemctl --user daemon-reload
        systemctl --user enable ollama.service
        systemctl --user start ollama.service
        
    else
        # No service found, try to start ollama directly
        log_warning "INSTALL" "No Ollama service found, starting Ollama in background..."
        
        # Set AMDGPU environment and start ollama
        export HSA_OVERRIDE_GFX_VERSION=10.3.0
        export ROCM_PATH=/opt/rocm
        export HIP_VISIBLE_DEVICES=0
        
        # Start ollama in background
        nohup ollama serve > /dev/null 2>&1 &
    fi
    
    # Wait for Ollama to be ready
    log_info "INSTALL" "Waiting for Ollama to be ready..."
    local attempts=0
    while ! curl -s http://127.0.0.1:11434/api/version > /dev/null 2>&1; do
        sleep 2
        attempts=$((attempts + 1))
        if [[ $attempts -gt 15 ]]; then
            log_warning "INSTALL" "Ollama may not be ready yet, continuing anyway..."
            break
        fi
    done
    
    # Pull LLaVA model
    log_info "INSTALL" "Pulling LLaVA model (this may take a while)..."
    log_warning "INSTALL" "This download is several GB - ensure you have good internet"
    
    if ollama pull llava:latest; then
        log_success "INSTALL" "LLaVA model installed successfully"
    else
        log_error "INSTALL" "Failed to install LLaVA model"
        log_info "INSTALL" "You can try again later with: ollama pull llava:latest"
    fi
}

# Function to setup dotfiles
setup_dotfiles() {
    log_info "INSTALL" "Setting up dotfiles symlinks..."
    
    if [[ -x "$SCRIPT_DIR/scripts/setup_symlinks.sh" ]]; then
        "$SCRIPT_DIR/scripts/setup_symlinks.sh" install
    else
        log_error "INSTALL" "Symlink setup script not found or not executable"
        exit 1
    fi
}

# Function to setup shell
setup_shell() {
    log_info "INSTALL" "Setting up fish shell..."
    
    # Check if fish is installed
    if ! command -v fish > /dev/null 2>&1; then
        log_error "INSTALL" "Fish shell not found - should have been installed with packages"
        return 1
    fi
    
    # Add fish to /etc/shells if not already there
    if ! grep -q "$(which fish)" /etc/shells; then
        log_info "INSTALL" "Adding fish to /etc/shells..."
        echo "$(which fish)" | sudo tee -a /etc/shells > /dev/null
    fi
    
    # Change user's default shell to fish
    local current_shell=$(getent passwd "$USER" | cut -d: -f7)
    local fish_path=$(which fish)
    
    if [[ "$current_shell" != "$fish_path" ]]; then
        log_info "INSTALL" "Changing default shell to fish..."
        if chsh -s "$fish_path"; then
            log_success "INSTALL" "Default shell changed to fish"
        else
            log_error "INSTALL" "Failed to change shell to fish"
            log_info "INSTALL" "You can change it manually with: chsh -s $(which fish)"
        fi
    else
        log_success "INSTALL" "Fish is already the default shell"
    fi
}

# Function to setup systemd services
setup_services() {
    log_info "INSTALL" "Setting up systemd services..."
    
    # Enable bluetooth if available
    if systemctl list-unit-files bluetooth.service > /dev/null 2>&1; then
        sudo systemctl enable bluetooth.service
        log_success "INSTALL" "Bluetooth service enabled"
    fi
    
    # Enable NetworkManager if available
    if systemctl list-unit-files NetworkManager.service > /dev/null 2>&1; then
        sudo systemctl enable NetworkManager.service
        log_success "INSTALL" "NetworkManager service enabled"
    fi
    
    # Start user services that should be running
    systemctl --user daemon-reload
    
    log_success "INSTALL" "System services configured"
}

# Function to setup environment for manual Hyprland start
setup_environment() {
    log_info "INSTALL" "Setting up environment for manual Hyprland start..."
    
    # Add environment variables to fish config
    local fish_env="$HOME/.config/fish/conf.d/clypr.fish"
    mkdir -p "$(dirname "$fish_env")"
    
    cat > "$fish_env" << EOF
# Clypr environment variables for Hyprland
set -gx XDG_SESSION_TYPE wayland
set -gx XDG_CURRENT_DESKTOP Hyprland
set -gx QT_QPA_PLATFORM wayland
set -gx GDK_BACKEND wayland
set -gx SDL_VIDEODRIVER wayland
set -gx CLUTTER_BACKEND wayland
set -gx _JAVA_AWT_WM_NONREPARENTING 1

# AMD GPU environment
set -gx HSA_OVERRIDE_GFX_VERSION 10.3.0
set -gx ROCM_PATH /opt/rocm
set -gx HIP_VISIBLE_DEVICES 0
EOF
    
    log_success "INSTALL" "Environment variables configured for fish shell"
    
    # Create missing Hyprland config files
    create_missing_hyprland_configs
}

# Function to create missing Hyprland config files
create_missing_hyprland_configs() {
    log_info "INSTALL" "Creating missing Hyprland configuration files..."
    
    local hypr_static="$SCRIPT_DIR/config_static/hypr"
    
    # Check if input.conf exists
    if [[ -f "$hypr_static/input.conf" ]]; then
        log_success "INSTALL" "input.conf already exists with Swedish keyboard"
    else
        log_info "INSTALL" "input.conf is missing - this is unexpected"
    fi
    
    # Create monitors.conf
    if [[ ! -f "$hypr_static/monitors.conf" ]]; then
        cat > "$hypr_static/monitors.conf" << EOF
# ~/.config/hypr/monitors.conf
# Monitor configuration

# Default monitor setup - auto detect
monitor=,preferred,auto,auto

# Example for specific monitor setup:
# monitor=DP-1,1920x1080@144,0x0,1
# monitor=HDMI-A-1,1920x1080@60,1920x0,1
EOF
        log_success "INSTALL" "Created monitors.conf"
    fi
    
    # Create workspaces.conf
    if [[ ! -f "$hypr_static/workspaces.conf" ]]; then
        cat > "$hypr_static/workspaces.conf" << EOF
# ~/.config/hypr/workspaces.conf
# Workspace rules and configuration

# Workspace rules
workspace = 1, monitor:DP-1, default:true
workspace = 2, monitor:DP-1
workspace = 3, monitor:DP-1
workspace = 4, monitor:DP-1
workspace = 5, monitor:DP-1
workspace = 6, monitor:DP-1
workspace = 7, monitor:DP-1
workspace = 8, monitor:DP-1
workspace = 9, monitor:DP-1
workspace = 10, monitor:DP-1

# Example workspace binding to specific monitor:
# workspace = 1, monitor:HDMI-A-1
# workspace = 2, monitor:DP-1
EOF
        log_success "INSTALL" "Created workspaces.conf"
    fi
    
    # Create window_rules.conf
    if [[ ! -f "$hypr_static/window_rules.conf" ]]; then
        cat > "$hypr_static/window_rules.conf" << EOF
# ~/.config/hypr/window_rules.conf
# Window rules and management

# Float specific windows
windowrule = float, ^(pavucontrol)$
windowrule = float, ^(blueman-manager)$
windowrule = float, ^(nm-applet)$
windowrule = float, ^(nm-connection-editor)$
windowrule = float, ^(file_progress)$
windowrule = float, ^(confirm)$
windowrule = float, ^(dialog)$
windowrule = float, ^(download)$
windowrule = float, ^(notification)$
windowrule = float, ^(error)$
windowrule = float, ^(splash)$
windowrule = float, ^(confirmreset)$
windowrule = float, title:^(Open File)(.*)$
windowrule = float, title:^(Select a File)(.*)$
windowrule = float, title:^(Choose wallpaper)(.*)$
windowrule = float, title:^(Open Folder)(.*)$
windowrule = float, title:^(Save As)(.*)$
windowrule = float, title:^(Library)(.*)$

# Size specific windows
windowrule = size 800 600, ^(pavucontrol)$
windowrule = size 600 400, ^(blueman-manager)$

# Workspace assignments
windowrule = workspace 2, ^(brave-browser)$
windowrule = workspace 2, ^(firefox)$
windowrule = workspace 3, ^(thunar)$
windowrule = workspace 4, ^(code)$
windowrule = workspace 5, ^(discord)$

# Opacity rules
windowrule = opacity 0.9 0.8, ^(kitty)$
windowrule = opacity 0.9 0.8, ^(foot)$
windowrule = opacity 0.95 0.9, ^(thunar)$

# Other rules
windowrule = center, ^(pavucontrol)$
windowrule = center, ^(blueman-manager)$
EOF
        log_success "INSTALL" "Created window_rules.conf"
    fi
}

# Function to create sample wallpapers directory
setup_wallpapers() {
    log_info "INSTALL" "Setting up wallpapers directory..."
    
    local wallpaper_dirs=(
        "$SCRIPT_DIR/wallpapers/landscapes"
        "$SCRIPT_DIR/wallpapers/abstract"
        "$SCRIPT_DIR/wallpapers/minimal"
    )
    
    for dir in "${wallpaper_dirs[@]}"; do
        mkdir -p "$dir"
    done
    
    log_success "INSTALL" "Wallpaper directories created"
    log_info "INSTALL" "Add your wallpapers to: $SCRIPT_DIR/wallpapers/"
}

# Function to test the installation
test_installation() {
    log_info "INSTALL" "Testing installation..."
    
    # Test color extraction (with fallback)
    if python3 "$SCRIPT_DIR/theme_engine/extract_colors.py" --help > /dev/null 2>&1; then
        log_success "INSTALL" "Color extraction engine working"
    else
        log_warning "INSTALL" "Color extraction may have issues"
    fi
    
    # Test template rendering
    if python3 "$SCRIPT_DIR/theme_engine/render_templates.py" --help > /dev/null 2>&1; then
        log_success "INSTALL" "Template renderer working"
    else
        log_warning "INSTALL" "Template renderer may have issues"
    fi
    
    # Check symlinks with detailed output
    log_info "INSTALL" "Checking symlink status..."
    "$SCRIPT_DIR/scripts/setup_symlinks.sh" verify
    
    # Check if critical symlinks exist
    local critical_configs=("hypr" "waybar" "fish")
    local all_good=true
    
    for config in "${critical_configs[@]}"; do
        if [[ -L "$HOME/.config/$config" ]]; then
            log_success "INSTALL" "$config symlink verified"
        else
            log_error "INSTALL" "$config symlink missing!"
            all_good=false
        fi
    done
    
    if [[ "$all_good" == "true" ]]; then
        log_success "INSTALL" "Critical symlinks verified"
    else
        log_warning "INSTALL" "Some critical symlinks are missing"
    fi
}

# Function to show completion message
show_completion() {
    print_header
    log_success "INSTALL" "Installation completed!"
    echo
    log_info "INSTALL" "Next steps:"
    echo -e "  1. Add wallpapers to: ${BLUE}$SCRIPT_DIR/wallpapers/${NC}"
    echo -e "  2. Test wallpaper picker: ${BLUE}$SCRIPT_DIR/scripts/wallpaper_picker.sh${NC}"
    echo -e "  3. Apply a theme: ${BLUE}$SCRIPT_DIR/scripts/apply_theme.sh /path/to/wallpaper.jpg${NC}"
    echo
    log_info "INSTALL" "Keybindings (add to Hyprland config):"
    echo -e "  ${BLUE}Super+Shift+W${NC} - Open wallpaper picker"
    echo
    log_warning "INSTALL" "Remember to:"
    echo "  • Start a new shell session or run 'exec fish' for shell changes"
    echo "  • Start Hyprland with the 'Hyprland' command"
    echo "  • Ensure Ollama service is running for AI color extraction"
    echo "  • Add wallpapers to the wallpapers directory"
    echo
    log_info "INSTALL" "For help: cat $SCRIPT_DIR/README.md"
}

# Function to display usage
usage() {
    echo "Usage: $0 [--skip-packages] [--skip-ollama] [--help]"
    echo
    echo "Options:"
    echo "  --skip-packages  Skip system package installation"
    echo "  --skip-ollama    Skip Ollama/LLaVA setup"
    echo "  --help           Show this help message"
    exit 1
}

# Main installation function
main() {
    local skip_packages=false
    local skip_ollama=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-packages)
                skip_packages=true
                shift
                ;;
            --skip-ollama)
                skip_ollama=true
                shift
                ;;
            --help)
                usage
                ;;
            *)
                echo "Unknown option: $1"
                usage
                ;;
        esac
    done
    
    print_header
    
    # System checks
    check_arch_linux
    check_amdgpu
    
    # Installation steps
    if [[ "$skip_packages" == "false" ]]; then
        install_packages
    else
        log_info "INSTALL" "Skipping package installation"
    fi
    
    if [[ "$skip_ollama" == "false" ]]; then
        setup_ollama
    else
        log_info "INSTALL" "Skipping Ollama setup"
    fi
    
    setup_dotfiles
    setup_wallpapers
    setup_shell
    setup_services
    setup_environment
    test_installation
    show_completion
}

# Run main function
main "$@"

# Ensure proper exit logging
trap 'log_script_end $?' EXIT