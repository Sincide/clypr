# Waybar Configuration Files

This directory contains multiple Waybar configuration layouts. The system uses **dual vertical bars** by default.

## Active Configurations (Used by System)

- **config-left.json** - Left vertical bar with launcher, workspaces, and controls
- **config-right.json** - Right vertical bar with system monitoring and tray

These are referenced by:
- `scripts/apply_theme.sh`
- `theme_engine/reload_apps.sh`
- `theme_engine/merge_configs.py`
- `config_static/hypr/exec.conf`

## Alternative Configurations (Not Used by Default)

- **config-top.json** - Horizontal bar at top of screen with full system monitoring
- **config-bottom.json** - Horizontal bar at bottom with additional modules

### How to Use Alternative Layouts

To switch to horizontal bars (top/bottom):

1. Edit `config_static/hypr/exec.conf` and change:
   ```
   exec-once = waybar -c ~/.config/waybar/config-left.json &
   exec-once = waybar -c ~/.config/waybar/config-right.json &
   ```
   to:
   ```
   exec-once = waybar -c ~/.config/waybar/config-top.json &
   exec-once = waybar -c ~/.config/waybar/config-bottom.json &
   ```

2. Update `theme_engine/reload_apps.sh` line 42-43 to reference config-top/bottom

3. Update `theme_engine/merge_configs.py` line 120 to copy config-top/bottom files

4. Restart Hyprland or reload configs

## Styling

All configurations share the same `style.css` which is dynamically themed based on your wallpaper selection.
