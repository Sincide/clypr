# GNU Stow - Simple Explanation

## What is Stow?

Think of Stow like **smart shortcuts** for your files. Instead of copying configuration files around, it creates links that point to your files.

## Why This is Good

### The Old Way (Bad)
```
You have config files scattered everywhere:
- Some in ~/.config/
- Some backed up in folders
- Hard to keep track of changes
- Easy to lose your settings
```

### The Stow Way (Good)
```
All your config files live in ONE place: ~/clypr/
Stow creates "shortcuts" that make them appear where apps expect them
Everything stays organized and backed up
```

## Simple Example

**What you have:**
```
~/clypr/config_static/waybar/config.json    (your file)
```

**What Stow does:**
```
~/.config/waybar/config.json → points to your file in ~/clypr/
```

**Result:**
- Waybar finds its config where it expects (in ~/.config/)
- But the file actually lives in your organized ~/clypr/ folder
- When you edit the file in ~/clypr/, Waybar sees the changes instantly

## How Our Script Works

### Step 1: Backup
```bash
# Our script backs up any existing configs
~/.config/waybar/ → ~/.config_backup_20240627_123456/waybar/
```

### Step 2: Create Links
```bash
# Our script creates organized links
~/.config/waybar/ → ~/clypr/[organized files]
~/.config/hyprland/ → ~/clypr/[organized files]
```

### Step 3: Everything Works
```
- All apps find their configs where they expect
- All your files stay organized in ~/clypr/
- Changes you make appear instantly everywhere
```

## What Commands Do

### Install Everything
```bash
./scripts/setup_symlinks.sh install
# Creates all the smart shortcuts
```

### Check Status
```bash
./scripts/setup_symlinks.sh status
# Shows you what's linked where
```

### Remove Everything
```bash
./scripts/setup_symlinks.sh remove
# Removes all shortcuts, restores your backups
```

## Tomorrow's Testing

1. **Run**: `./install.sh` (does everything automatically)
2. **Check**: `./scripts/setup_symlinks.sh status` (see what happened)
3. **Test**: Edit a file in ~/clypr/ and see it change in ~/.config/ instantly
4. **Use**: Run the wallpaper picker and enjoy!

**That's it!** Stow is just smart shortcuts that keep your files organized. 😊

Good night! Tomorrow we'll test this awesome system! 🌙