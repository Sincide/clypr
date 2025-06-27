# GNU Stow Explained - Dotfiles Management Made Simple

## What is GNU Stow?

GNU Stow is a **symlink manager** that helps you organize and manage configuration files (dotfiles). Instead of copying files around, it creates symbolic links from a central repository to their target locations.

## Why Use Stow for Dotfiles?

### Without Stow (Traditional Method)
```bash
# Manual copying - messy and hard to track
cp ~/.config/hyprland/hyprland.conf ~/dotfiles/backup/
cp ~/dotfiles/hyprland.conf ~/.config/hyprland/
# If you update dotfiles, you have to remember to copy back
```

### With Stow (Symlink Method)
```bash
# One command creates all symlinks
stow dotfiles
# Files stay in your repository, but appear in the right places
# Changes to your repository immediately affect the system
```

## How Stow Works

### Directory Structure Concept
Stow treats your dotfiles repository as a **"stow directory"** containing **"packages"**. Each package mirrors the target directory structure.

```
~/clypr/                          # Stow directory
└── stow_packages/                # Created by our setup script
    └── dotfiles/                 # Package name
        ├── .config/              # Mirrors ~/.config/
        │   ├── hyprland/
        │   │   ├── hyprland.conf
        │   │   ├── input.conf
        │   │   └── theme.conf
        │   ├── waybar/
        │   │   ├── config-top.json
        │   │   ├── config-bottom.json
        │   │   └── style.css
        │   └── kitty/
        │       └── kitty.conf
        └── .gtkrc-2.0            # Mirrors ~/.gtkrc-2.0
```

### Symlink Creation
When you run `stow dotfiles`, it creates symlinks:

```bash
# These symlinks are created:
~/.config/hyprland/hyprland.conf → ~/clypr/stow_packages/dotfiles/.config/hyprland/hyprland.conf
~/.config/waybar/config-top.json → ~/clypr/stow_packages/dotfiles/.config/waybar/config-top.json
~/.gtkrc-2.0 → ~/clypr/stow_packages/dotfiles/.gtkrc-2.0
```

## Our Stow Implementation

### How Our Script Sets Up Stow

```bash
# scripts/setup_symlinks.sh does this:

1. Backup existing configs
2. Create stow package structure:
   mkdir -p ~/clypr/stow_packages/dotfiles/.config
   
3. Copy static configs to stow structure:
   cp -r ~/clypr/config_static/* ~/clypr/stow_packages/dotfiles/.config/
   
4. Handle special cases (GTK files go to home directory):
   cp ~/clypr/config_static/gtk/gtkrc-2.0 ~/clypr/stow_packages/dotfiles/.gtkrc-2.0
   
5. Apply symlinks:
   cd ~
   stow -d ~/clypr/stow_packages -t ~ dotfiles
```

### What Happens When You Install

**Before Stow:**
```
~/.config/hyprland/     # Your existing config (backed up)
~/.config/waybar/       # Your existing config (backed up)
```

**After Stow:**
```
~/.config/hyprland/     # → symlink to ~/clypr/stow_packages/dotfiles/.config/hyprland/
~/.config/waybar/       # → symlink to ~/clypr/stow_packages/dotfiles/.config/waybar/
```

## Key Stow Commands

### Install (Create Symlinks)
```bash
# From your home directory
cd ~
stow -d ~/clypr/stow_packages -t ~ dotfiles

# Our script does this for you:
./scripts/setup_symlinks.sh install
```

### Remove (Delete Symlinks)
```bash
# Remove all symlinks
stow -d ~/clypr/stow_packages -t ~ -D dotfiles

# Our script does this:
./scripts/setup_symlinks.sh remove
```

### Check Status
```bash
# See what's symlinked
./scripts/setup_symlinks.sh status
```

## Why Our Approach is Smart

### 1. **Safe Backups**
- Existing configs are backed up before symlinking
- No data loss if something goes wrong

### 2. **Dynamic Updates**
- When theme engine updates configs, changes appear immediately
- No need to re-stow after theme changes

### 3. **Easy Uninstall**
- One command removes all symlinks
- Restore backups if needed

### 4. **Version Control Friendly**
- All configs stay in your repository
- Track changes with git
- Share configs easily

## Example Workflow

### Daily Usage
```bash
# 1. Change wallpaper (automatically updates all configs)
~/clypr/scripts/wallpaper_picker.sh

# 2. Edit a config file
vim ~/clypr/config_static/hyprland/hyprland.conf
# Changes immediately appear in ~/.config/hyprland/hyprland.conf (it's a symlink!)

# 3. Hyprland automatically picks up the changes
```

### Maintenance
```bash
# Check symlink status
~/clypr/scripts/setup_symlinks.sh status

# Remove all symlinks
~/clypr/scripts/setup_symlinks.sh remove

# Reinstall symlinks
~/clypr/scripts/setup_symlinks.sh install
```

## Troubleshooting Stow

### Common Issues

**"stow: WARNING! stowing X would cause conflicts"**
- Solution: Remove existing files/directories first
- Our script backs them up automatically

**"Target directory doesn't exist"**
- Solution: Stow will create parent directories automatically
- Make sure you're in the right directory when running stow

**"Symlinks broken after moving repository"**
- Solution: Remove and re-stow from new location
- Our script handles this automatically

### Manual Stow Commands (if needed)

```bash
# Dry run (see what would happen)
stow -n -d ~/clypr/stow_packages -t ~ dotfiles

# Verbose output (see what's happening)
stow -v -d ~/clypr/stow_packages -t ~ dotfiles

# Force overwrite conflicts
stow --adopt -d ~/clypr/stow_packages -t ~ dotfiles
```

## Benefits of Our Stow Setup

1. **Centralized Management**: All configs in one repository
2. **Instant Updates**: Theme changes apply immediately
3. **Safe Installation**: Backups prevent data loss
4. **Easy Sharing**: Repository contains everything
5. **Professional**: Industry standard for dotfiles management

## File Locations After Setup

```
# Your repository (source of truth)
~/clypr/config_static/hyprland/hyprland.conf

# Stow package structure
~/clypr/stow_packages/dotfiles/.config/hyprland/hyprland.conf

# System location (symlinked)
~/.config/hyprland/hyprland.conf → ~/clypr/stow_packages/dotfiles/.config/hyprland/hyprland.conf
```

## Tomorrow's Testing Plan

1. **Install**: `./install.sh` (sets up packages + stow)
2. **Verify**: `./scripts/setup_symlinks.sh status`
3. **Test**: Change a config file and see it instantly appear in ~/.config/
4. **Theme**: Run wallpaper picker and watch everything update

Stow makes dotfiles management elegant and safe! 🎯