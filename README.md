# Dynamic Theming Dotfiles for Hyprland

A modular, AI-powered dotfiles system for Arch Linux with Hyprland that automatically extracts color palettes from wallpapers using LLaVA and applies cohesive themes across all desktop applications.

## Features

- 🎨 **AI-Powered Color Extraction**: Uses LLaVA via Ollama to extract MaterialYou color palettes
- 🖼️ **Wallpaper Picker**: Beautiful rofi-wayland interface with thumbnails
- ⚡ **Atomic Theme Application**: All apps change theme simultaneously 
- 🔄 **Template System**: Minimal, DRY template approach with smart merging
- 📱 **Dual Waybar**: Mirrored vertical bars with comprehensive system monitoring
- 🔧 **Modular Hyprland**: Clean, organized configuration with Swedish keyboard support
- 🖥️ **AMDGPU Optimized**: Designed for AMD graphics cards
- 📦 **Symlink Management**: GNU Stow-based configuration management

## Supported Applications

- **Window Manager**: Hyprland (modular config with Swedish layout)
- **Bars**: Dual Waybar instances (left/right)
- **Launcher**: Rofi-wayland with custom themes
- **Notifications**: Dunst
- **Terminals**: Kitty, Foot
- **Shell**: Fish with custom themes
- **System Monitor**: Btop
- **GTK**: GTK2, GTK3, GTK4 theming
- **Wallpapers**: Swww with smooth transitions

## Installation

### 🚀 Automatic Installation (Recommended)

**Fresh Arch Linux installation required** - this will install all dependencies, setup services, and configure everything automatically:

```bash
# 1. Clone the repository
git clone https://github.com/Sincide/clypr-dynamic-theming.git ~/clypr
cd ~/clypr

# 2. Run the automated installer
./install.sh

# 3. Add your wallpapers
cp /path/to/your/wallpapers/* wallpapers/landscapes/

# 4. Start theming!
./scripts/wallpaper_picker.sh
```

**What the installer does:**
- ✅ Installs all required packages (including yay-bin for AUR)
- ✅ Sets up Ollama with LLaVA model for AI color extraction
- ✅ Configures AMDGPU optimization for better performance
- ✅ Creates symlinks using GNU Stow
- ✅ Backs up your existing configurations
- ✅ Tests the entire system

### 🔧 Manual Installation (Advanced)

If you prefer to install components manually:

```bash
# Install system packages
sudo pacman -S hyprland waybar rofi-wayland swww dunst kitty foot fish btop
sudo pacman -S python python-requests imagemagick stow base-devel git
sudo pacman -S ttf-jetbrains-mono papirus-icon-theme grim slurp wl-clipboard

# Install yay for AUR packages
git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si

# Install Ollama and LLaVA
curl -fsSL https://ollama.com/install.sh | sh
systemctl --user enable --now ollama
ollama pull llava:latest

# Setup dotfiles
./scripts/setup_symlinks.sh install
```

## Usage

### Changing Wallpaper & Theme

**GUI Method:**
- Use `Super+Shift+W` (or run `wallpaper_picker.sh`)
- Browse wallpapers with thumbnails in rofi
- Select wallpaper to automatically apply theme

**CLI Method:**
```bash
# Apply theme from specific wallpaper
./scripts/apply_theme.sh /path/to/wallpaper.jpg

# Restore previous theme
./scripts/apply_theme.sh restore
```

### Managing Symlinks

```bash
# Install symlinks
./scripts/setup_symlinks.sh install

# Check symlink status  
./scripts/setup_symlinks.sh status

# Remove symlinks
./scripts/setup_symlinks.sh remove

# Verify symlinks are working
./scripts/setup_symlinks.sh verify
```

## How It Works

### Workflow Overview

1. **Wallpaper Selection**: User selects wallpaper via rofi interface
2. **Color Extraction**: LLaVA analyzes image and extracts MaterialYou palette
3. **Template Rendering**: Minimal templates filled with color variables
4. **Config Merging**: Templates merged with static application configs
5. **Atomic Application**: All applications reload with new theme simultaneously

### Directory Structure

```
clypr/
├── config_templates/     # Minimal theme templates (colors/fonts only)
├── config_static/        # Static app configurations  
├── theme_engine/         # Python scripts for theming
├── scripts/              # User-facing bash scripts
├── wallpapers/           # Organized wallpaper collection
└── docs/                 # Extended documentation
```

### Template System

Templates contain **only** theming variables:

```css
/* Example: waybar/style.css.tmpl */
window#waybar {
    background-color: {{background_color}};
    color: {{text_primary_color}};
    font-family: {{font_family}};
}

button:hover {
    background-color: {{primary_color}}60;
}
```

Final configs are dynamically assembled by merging templates with static configurations.

## Keyboard Shortcuts

- `Super+Return`: Terminal (kitty)
- `Super+R`: App launcher (rofi)
- `Super+W`: Web browser
- `Super+Shift+W`: **Wallpaper picker** 
- `Super+Q`: Kill active window
- `Super+1-0`: Switch workspaces
- `Super+Shift+1-0`: Move window to workspace

Swedish keyboard layout with numlock enabled by default.

## Configuration

### Adding New Applications

1. **Create static config** in `config_static/app_name/`
2. **Create theme template** in `config_templates/app_name/config.tmpl`  
3. **Update merge_configs.py** to handle the new app
4. **Update reload_apps.sh** to restart the application

### Customizing Colors

Edit the color extraction prompts in `theme_engine/extract_colors.py` or manually edit generated theme files in `theme_engine/theme_data/current.json`.

### Adding Fonts

```bash
# Install fonts to system
sudo pacman -S ttf-font-name

# Update font variables in render_templates.py
# Fonts will be applied on next theme change
```

## Troubleshooting

### LLaVA Not Working
```bash
# Check Ollama status
systemctl --user status ollama

# Test LLaVA model
ollama run llava:latest

# Check available models
ollama list
```

### Symlinks Broken
```bash
# Check symlink status
./scripts/setup_symlinks.sh status

# Reinstall symlinks
./scripts/setup_symlinks.sh remove
./scripts/setup_symlinks.sh install
```

### Theme Not Applying
```bash
# Check theme data
cat theme_engine/theme_data/current.json

# Manually reload applications
hyprctl reload
pkill waybar && waybar &
```

## AMDGPU Optimization

This setup is optimized for AMD graphics:

- Ollama configured with ROCm/HIP support
- No NVIDIA-specific dependencies
- AMDGPU environment variables set in Ollama setup

## File Locations

After installation, configs are symlinked to:

- `~/.config/hyprland/` - Hyprland configuration
- `~/.config/waybar/` - Waybar configurations  
- `~/.config/rofi/` - Rofi themes
- `~/.config/kitty/` - Terminal configuration
- `~/.gtkrc-2.0` - GTK2 theme
- `~/.config/gtk-3.0/` - GTK3 theme
- `~/.config/gtk-4.0/` - GTK4 theme

## Contributing

This is a personal dotfiles setup, but feel free to:

1. Fork and adapt for your needs
2. Report issues or improvements
3. Add support for additional applications
4. Improve the AI color extraction prompts

## Credits

- **Hyprland**: Amazing Wayland compositor
- **LLaVA**: Large Language and Vision Assistant  
- **Ollama**: Local LLM inference
- **Catppuccin**: Color scheme inspiration for fallbacks
- **Font Awesome**: Icons for Waybar

---

**Made for Arch Linux + Hyprland + AMDGPU**  
Swedish keyboard layout | Dynamic AI theming | Minimal & modular