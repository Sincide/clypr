#!/usr/bin/env python3
# theme_engine/merge_configs.py  
# Config merger - combines static configs with rendered templates

import json
import shutil
from pathlib import Path
from typing import Dict, List
import configparser

class ConfigMerger:
    """Merges static application configs with rendered theme templates."""
    
    def __init__(self, dotfiles_dir: str):
        self.dotfiles_dir = Path(dotfiles_dir)
        self.static_dir = self.dotfiles_dir / "config_static"
        self.rendered_dir = self.dotfiles_dir / "theme_engine" / "theme_data" / "rendered"
        self.output_dir = Path.home() / ".config"
        
        # Backup directory for config files
        self.backup_dir = self.dotfiles_dir / "theme_engine" / "theme_data" / "backups"
        self.backup_dir.mkdir(parents=True, exist_ok=True)
    
    def _backup_existing_config(self, config_path: Path) -> None:
        """Backup existing config file before overwriting."""
        if config_path.exists():
            backup_path = self.backup_dir / f"{config_path.name}.backup"
            shutil.copy2(config_path, backup_path)
    
    def _merge_text_files(self, static_file: Path, rendered_file: Path, output_file: Path) -> None:
        """Merge plain text config files."""
        
        # Backup existing
        self._backup_existing_config(output_file)
        
        # Ensure output directory exists
        output_file.parent.mkdir(parents=True, exist_ok=True)
        
        # Start with static content
        merged_content = ""
        if static_file.exists():
            with open(static_file, 'r') as f:
                merged_content = f.read()
        
        # Append theme content
        if rendered_file.exists():
            with open(rendered_file, 'r') as f:
                theme_content = f.read()
            
            # Add separator comment
            merged_content += "\n\n# === DYNAMIC THEME SECTION ===\n"
            merged_content += theme_content
        
        # Write merged content
        with open(output_file, 'w') as f:
            f.write(merged_content)
    
    def _merge_json_files(self, static_file: Path, rendered_file: Path, output_file: Path) -> None:
        """Merge JSON config files."""
        
        # Backup existing
        self._backup_existing_config(output_file)
        
        # Ensure output directory exists  
        output_file.parent.mkdir(parents=True, exist_ok=True)
        
        merged_data = {}
        
        # Load static data
        if static_file.exists():
            with open(static_file, 'r') as f:
                merged_data = json.load(f)
        
        # Merge theme data
        if rendered_file.exists():
            with open(rendered_file, 'r') as f:
                theme_data = json.load(f)
            
            # Deep merge dictionaries
            self._deep_merge_dict(merged_data, theme_data)
        
        # Write merged data
        with open(output_file, 'w') as f:
            json.dump(merged_data, f, indent=2)
    
    def _deep_merge_dict(self, base: dict, overlay: dict) -> None:
        """Deep merge two dictionaries."""
        for key, value in overlay.items():
            if key in base and isinstance(base[key], dict) and isinstance(value, dict):
                self._deep_merge_dict(base[key], value)
            else:
                base[key] = value
    
    def merge_hyprland_config(self) -> None:
        """Merge Hyprland configuration."""
        app_name = "hyprland"
        
        # Main config file
        static_main = self.static_dir / app_name / "hyprland.conf"
        output_main = self.output_dir / app_name / "hyprland.conf"
        
        if static_main.exists():
            shutil.copy2(static_main, output_main)
            output_main.parent.mkdir(parents=True, exist_ok=True)
        
        # Theme config (colors, fonts)
        rendered_theme = self.rendered_dir / app_name / "theme.conf"
        output_theme = self.output_dir / app_name / "theme.conf"
        
        if rendered_theme.exists():
            shutil.copy2(rendered_theme, output_theme)
        
        print(f"✓ Merged {app_name} config")
    
    def merge_waybar_config(self) -> None:
        """Merge Waybar configuration."""
        app_name = "waybar"
        
        # Copy static config JSON files
        for config_file in ["config-top.json", "config-bottom.json"]:
            static_file = self.static_dir / app_name / config_file
            output_file = self.output_dir / app_name / config_file
            
            if static_file.exists():
                self.output_dir.mkdir(parents=True, exist_ok=True)
                output_file.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(static_file, output_file)
        
        # Merge CSS files
        static_css = self.static_dir / app_name / "style.css"
        rendered_css = self.rendered_dir / app_name / "style.css"
        output_css = self.output_dir / app_name / "style.css"
        
        self._merge_text_files(static_css, rendered_css, output_css)
        
        print(f"✓ Merged {app_name} config")
    
    def merge_generic_config(self, app_name: str, config_files: List[str]) -> None:
        """Generic config merger for simple applications."""
        
        for config_file in config_files:
            static_file = self.static_dir / app_name / config_file
            rendered_file = self.rendered_dir / app_name / config_file
            output_file = self.output_dir / app_name / config_file
            
            if config_file.endswith('.json'):
                self._merge_json_files(static_file, rendered_file, output_file)
            else:
                self._merge_text_files(static_file, rendered_file, output_file)
        
        print(f"✓ Merged {app_name} config")
    
    def merge_all_configs(self) -> None:
        """Merge all application configurations."""
        
        print("Merging static configs with rendered themes...")
        
        # Hyprland (special handling)
        self.merge_hyprland_config()
        
        # Waybar (special handling)
        self.merge_waybar_config()
        
        # Generic applications
        app_configs = {
            "rofi": ["config.rasi"],
            "dunst": ["dunstrc"],
            "kitty": ["kitty.conf"],
            "foot": ["foot.ini"],
            "fish": ["config.fish"],
            "btop": ["btop.conf"],
        }
        
        for app_name, config_files in app_configs.items():
            self.merge_generic_config(app_name, config_files)
        
        # GTK configs (special handling for different versions)
        self._merge_gtk_configs()
        
        print("All configs merged successfully!")
    
    def _merge_gtk_configs(self) -> None:
        """Merge GTK theme configurations."""
        
        # GTK2
        static_gtk2 = self.static_dir / "gtk" / "gtkrc-2.0"
        rendered_gtk2 = self.rendered_dir / "gtk" / "gtk-2.0"
        output_gtk2 = Path.home() / ".gtkrc-2.0"
        self._merge_text_files(static_gtk2, rendered_gtk2, output_gtk2)
        
        # GTK3
        static_gtk3 = self.static_dir / "gtk" / "settings.ini"
        rendered_gtk3 = self.rendered_dir / "gtk" / "gtk-3.0"
        output_gtk3 = self.output_dir / "gtk-3.0" / "settings.ini"
        self._merge_text_files(static_gtk3, rendered_gtk3, output_gtk3)
        
        # GTK4
        static_gtk4 = self.static_dir / "gtk" / "settings.ini"
        rendered_gtk4 = self.rendered_dir / "gtk" / "gtk-4.0"
        output_gtk4 = self.output_dir / "gtk-4.0" / "settings.ini"
        self._merge_text_files(static_gtk4, rendered_gtk4, output_gtk4)
        
        print("✓ Merged GTK configs")

def main():
    """CLI entry point for config merging."""
    
    # Determine dotfiles directory
    script_dir = Path(__file__).parent
    dotfiles_dir = script_dir.parent
    
    # Merge all configs
    merger = ConfigMerger(str(dotfiles_dir))
    merger.merge_all_configs()

if __name__ == "__main__":
    main()
