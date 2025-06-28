# Wallpapers Directory

This directory contains wallpapers organized by category for the dynamic theming system.

## Directory Structure

- `abstract/` - Abstract and geometric wallpapers
- `dark/` - Dark-themed wallpapers
- `gaming/` - Gaming-related wallpapers  
- `landscapes/` - Nature and landscape wallpapers
- `minimal/` - Minimalist wallpapers
- `nature/` - Nature and outdoor wallpapers
- `space/` - Space and astronomy wallpapers
- `test/` - Sample wallpapers for testing (included in git)
- `thumbnails/` - Auto-generated thumbnails (not in git)

## Supported Formats

The wallpaper picker supports these image formats:
- JPEG (`.jpg`, `.jpeg`)
- PNG (`.png`)
- WebP (`.webp`)

## Adding Wallpapers

1. Place wallpapers in the appropriate category directory
2. Run the wallpaper picker: `./scripts/wallpaper_picker.sh`
3. Select a wallpaper to automatically apply the dynamic theme

## Theme Generation

When you select a wallpaper, the system:
1. Uses LLaVA (via Ollama) to extract a MaterialYou color palette
2. Renders all application themes with the extracted colors
3. Applies the theme atomically across all configured applications

## Notes

- Sample wallpapers in `test/` are included for new installations
- Personal wallpapers in other directories are excluded from git
- Thumbnails are generated automatically when needed