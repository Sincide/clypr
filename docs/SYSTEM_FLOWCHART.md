# Dynamic Theming System Flowchart

```
                    ┌─────────────────────────────────────────────────────┐
                    │               USER INTERACTIONS                     │
                    └─────────────────────────────────────────────────────┘
                                               │
                    ┌─────────────────────────────────────────────────────┐
                    │  1. User runs wallpaper_picker.sh                  │
                    │  2. User presses Super+Shift+W                     │
                    │  3. User clicks Waybar wallpaper button            │
                    │  4. Manual: apply_theme.sh /path/to/wallpaper.jpg  │
                    └─────────────────────────────────────────────────────┘
                                               │
                                               ▼
                    ┌─────────────────────────────────────────────────────┐
                    │              WALLPAPER SELECTION                   │
                    │                                                     │
                    │  wallpaper_picker.sh                              │
                    │  ├─ Scans ~/clypr/wallpapers/*                    │
                    │  ├─ Generates thumbnails (ImageMagick)            │
                    │  ├─ Shows rofi-wayland interface                  │
                    │  ├─ User selects wallpaper                        │
                    │  └─ Calls apply_theme.sh with wallpaper path      │
                    └─────────────────────────────────────────────────────┘
                                               │
                                               ▼
                    ┌─────────────────────────────────────────────────────┐
                    │            THEME APPLICATION WORKFLOW              │
                    │                                                     │
                    │  apply_theme.sh                                    │
                    │  ├─ 1. Color Extraction                           │
                    │  ├─ 2. Template Rendering                         │
                    │  ├─ 3. Config Merging                             │
                    │  ├─ 4. Wallpaper Setting                          │
                    │  └─ 5. Application Reload                         │
                    └─────────────────────────────────────────────────────┘
                                               │
                    ┌────────────────────────┬───────────────────────────────┐
                    ▼                        ▼                               ▼
        ┌─────────────────────┐  ┌─────────────────────┐        ┌─────────────────────┐
        │   COLOR EXTRACTION  │  │  TEMPLATE RENDERING │        │   CONFIG MERGING    │
        │                     │  │                     │        │                     │
        │ extract_colors.py   │  │ render_templates.py │        │ merge_configs.py    │
        │ ├─ Check cache      │  │ ├─ Load current.json│        │ ├─ Static configs   │
        │ ├─ Call LLaVA/Ollama│  │ ├─ Generate vars    │        │ ├─ Rendered templates│
        │ ├─ Fallback palette │  │ ├─ Process *.tmpl   │        │ ├─ Merge & output   │
        │ ├─ Save current.json│  │ └─ Save to rendered/│        │ └─ ~/.config/*      │
        │ └─ Cache palette    │  └─────────────────────┘        └─────────────────────┘
        └─────────────────────┘                                              │
                    │                                                       │
                    ▼                                                       ▼
        ┌─────────────────────────────────────────────────────────────────────────────┐
        │                      OLLAMA/LLaVA INTEGRATION                               │
        │                                                                             │
        │  LLaVA Model (via Ollama API)                                              │
        │  ├─ Image analysis with MaterialYou extraction prompt                      │
        │  ├─ Returns 9-color palette: primary, secondary, tertiary,                 │
        │  │   background, surface, accent, text_primary, text_secondary, text_accent│
        │  ├─ AMDGPU optimized with ROCm                                              │
        │  └─ Fallback to Catppuccin if unavailable                                  │
        └─────────────────────────────────────────────────────────────────────────────┘
                                               │
                                               ▼
        ┌─────────────────────────────────────────────────────────────────────────────┐
        │                        TEMPLATE PROCESSING                                  │
        │                                                                             │
        │  config_templates/ (Minimal theme-only templates)                          │
        │  ├─ hyprland/theme.conf.tmpl     → Colors, borders, shadows                │
        │  ├─ waybar/style.css.tmpl        → Colors, fonts for top/bottom bars       │
        │  ├─ kitty/theme.conf.tmpl        → Terminal color scheme                   │
        │  ├─ rofi/theme.rasi.tmpl         → Launcher colors                         │
        │  ├─ dunst/dunstrc.tmpl           → Notification colors                     │
        │  └─ gtk/*.tmpl                   → GTK2/3/4 themes                         │
        │                                                                             │
        │  Variables injected:                                                        │
        │  ├─ {{primary_color}}, {{background_color}}, etc.                         │
        │  ├─ {{font_family}}, {{font_size}}, etc.                                  │
        │  └─ RGB variants, opacity variants                                         │
        └─────────────────────────────────────────────────────────────────────────────┘
                                               │
                                               ▼
        ┌─────────────────────────────────────────────────────────────────────────────┐
        │                       CONFIG MERGING & OUTPUT                              │
        │                                                                             │
        │  config_static/ + theme_data/rendered/ → ~/.config/                        │
        │                                                                             │
        │  ├─ Hyprland: hyprland.conf (includes theme.conf)                          │
        │  ├─ Waybar: config-top.json + config-bottom.json + style.css               │
        │  ├─ Applications: kitty/, rofi/, dunst/, etc.                              │
        │  └─ GTK: ~/.gtkrc-2.0, ~/.config/gtk-3.0/, ~/.config/gtk-4.0/             │
        └─────────────────────────────────────────────────────────────────────────────┘
                                               │
                                               ▼
        ┌─────────────────────────────────────────────────────────────────────────────┐
        │                      WALLPAPER & APP RELOAD                                │
        │                                                                             │
        │  1. swww img (set wallpaper with transition)                               │
        │  2. reload_apps.sh:                                                        │
        │     ├─ hyprctl reload (Hyprland config)                                    │
        │     ├─ pkill waybar && restart top/bottom bars                             │
        │     ├─ dunstctl reload (notifications)                                     │
        │     ├─ SIGUSR1 to kitty (terminal reload)                                  │
        │     ├─ gsettings GTK theme update                                          │
        │     └─ Desktop notification                                                │
        └─────────────────────────────────────────────────────────────────────────────┘
                                               │
                                               ▼
        ┌─────────────────────────────────────────────────────────────────────────────┐
        │                        FINAL RESULT                                        │
        │                                                                             │
        │  ✓ Wallpaper set with smooth transition                                    │
        │  ✓ Hyprland: Borders, shadows, window rules themed                         │
        │  ✓ Waybar: Top bar (workspaces, window, clock, system)                     │
        │  ✓ Waybar: Bottom bar (date, uptime, disk, audio, power)                   │
        │  ✓ Terminals: kitty/foot with matching colors                              │
        │  ✓ Rofi: Launcher with themed interface                                    │
        │  ✓ Dunst: Notifications matching color scheme                              │
        │  ✓ GTK: System-wide theme for GUI applications                             │
        │  ✓ All changes applied atomically                                          │
        └─────────────────────────────────────────────────────────────────────────────┘


                        ┌─────────────────────────────────────────┐
                        │             LOGGING SYSTEM              │
                        │                                         │
                        │  ~/.local/share/clypr/theme.log         │
                        │  ├─ All script execution                │
                        │  ├─ Error tracking                      │
                        │  ├─ Python errors                       │
                        │  ├─ Command execution                   │
                        │  ├─ LLaVA API calls                     │
                        │  └─ Application reload status           │
                        │                                         │
                        │  Log rotation: 10MB max, 5 files       │
                        │  Commands:                              │
                        │  ├─ tail -f ~/.local/share/clypr/theme.log│
                        │  ├─ DEBUG=1 for verbose output          │
                        │  └─ ~/clypr/theme_engine/logger.sh      │
                        └─────────────────────────────────────────┘


                        ┌─────────────────────────────────────────┐
                        │        FILE SYSTEM LAYOUT              │
                        │                                         │
                        │  ~/clypr/ (dotfiles repository)        │
                        │  ├─ config_static/      (base configs) │
                        │  ├─ config_templates/   (theme vars)   │
                        │  ├─ theme_engine/       (Python/bash)  │
                        │  ├─ scripts/            (user scripts) │
                        │  ├─ wallpapers/         (images)       │
                        │  └─ install.sh          (setup)        │
                        │                                         │
                        │  ~/.config/ (symlinked via GNU Stow)   │
                        │  ├─ hyprland/                          │
                        │  ├─ waybar/                            │
                        │  ├─ kitty/, rofi/, dunst/, etc.        │
                        │  └─ gtk-3.0/, gtk-4.0/                 │
                        │                                         │
                        │  ~/.local/share/clypr/theme.log        │
                        └─────────────────────────────────────────┘


                        ┌─────────────────────────────────────────┐
                        │          DEPENDENCIES                   │
                        │                                         │
                        │  System Packages (pacman):             │
                        │  ├─ hyprland, waybar, rofi-wayland     │
                        │  ├─ swww, dunst, kitty, foot, fish     │
                        │  ├─ python, python-requests            │
                        │  ├─ imagemagick, stow, btop            │
                        │  ├─ grim, slurp, wl-clipboard          │
                        │  └─ base-devel, git                    │
                        │                                         │
                        │  AUR (via yay-bin):                    │
                        │  └─ (future extensions)                │
                        │                                         │
                        │  External Services:                    │
                        │  ├─ Ollama (http://127.0.0.1:11434)    │
                        │  ├─ LLaVA model (AI color extraction)  │
                        │  └─ ROCm/HIP (AMDGPU acceleration)     │
                        └─────────────────────────────────────────┘


                        ┌─────────────────────────────────────────┐
                        │      KEYBOARD SHORTCUTS                │
                        │                                         │
                        │  Super+Shift+W    → Wallpaper picker   │
                        │  Super+R          → App launcher       │
                        │  Super+Return     → Terminal           │
                        │  Super+1-0        → Workspaces         │
                        │  Print            → Screenshot          │
                        │  XF86Audio*       → Volume control     │
                        │                                         │
                        │  Swedish keyboard layout + numlock     │
                        └─────────────────────────────────────────┘
```

## Data Flow Summary

1. **Input**: User selects wallpaper via rofi interface
2. **Analysis**: LLaVA AI extracts MaterialYou color palette 
3. **Processing**: Templates filled with colors, merged with static configs
4. **Output**: All applications instantly adopt cohesive theme
5. **Logging**: Complete operation logged to central file

## Key Features

- **Atomic**: All apps change simultaneously, no half-themed state
- **AI-Powered**: Real LLaVA color extraction, not fake placeholders
- **Modular**: Clean separation of static config vs dynamic theming
- **Cacheable**: Color palettes cached per wallpaper for performance
- **AMDGPU**: Optimized for AMD graphics with ROCm acceleration
- **Swedish**: Keyboard layout with numlock enabled
- **Horizontal Bars**: Top/bottom Waybar without battery/wifi/music
- **Comprehensive Logging**: All operations logged to single file