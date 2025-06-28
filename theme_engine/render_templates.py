#!/usr/bin/env python3
# theme_engine/render_templates.py
# Template rendering engine for dynamic theming
# Processes minimal templates with color/font variables

import json
import os
import re
from pathlib import Path
from typing import Dict, Any, List
import shutil

class ThemeRenderer:
    """Renders minimal theme templates with extracted color palette and font data."""
    
    def __init__(self, dotfiles_dir: str):
        self.dotfiles_dir = Path(dotfiles_dir)
        self.templates_dir = self.dotfiles_dir / "config_templates"
        self.theme_data_dir = self.dotfiles_dir / "theme_engine" / "theme_data"
        self.current_theme_file = self.theme_data_dir / "current.json"
        self.rendered_dir = self.theme_data_dir / "rendered"
        
        # Create directories
        self.rendered_dir.mkdir(parents=True, exist_ok=True)
    
    def _load_current_theme(self) -> Dict[str, Any]:
        """Load current theme data including palette and metadata."""
        if not self.current_theme_file.exists():
            raise FileNotFoundError(f"No current theme found at {self.current_theme_file}")
        
        with open(self.current_theme_file, 'r') as f:
            return json.load(f)
    
    def _get_template_variables(self, theme_data: Dict[str, Any]) -> Dict[str, str]:
        """Generate all template variables from theme data."""
        palette = theme_data["palette"]
        
        # Base color variables
        variables = {
            # Primary colors
            "primary_color": palette["primary"],
            "secondary_color": palette["secondary"], 
            "tertiary_color": palette["tertiary"],
            "accent_color": palette["accent"],
            
            # Background colors
            "background_color": palette["background"],
            "surface_color": palette["surface"],
            
            # Text colors
            "text_primary_color": palette["text_primary"],
            "text_secondary_color": palette["text_secondary"],
            "text_accent_color": palette["text_accent"],
            
            # Wallpaper info
            "wallpaper_path": theme_data["wallpaper_path"],
            "wallpaper_name": theme_data["wallpaper_name"],
        }
        
        # Generate RGB variants for applications that need them
        for key, hex_color in palette.items():
            rgb_values = self._hex_to_rgb(hex_color)
            variables[f"{key}_rgb"] = f"{rgb_values[0]}, {rgb_values[1]}, {rgb_values[2]}"
            variables[f"{key}_r"] = str(rgb_values[0])
            variables[f"{key}_g"] = str(rgb_values[1])
            variables[f"{key}_b"] = str(rgb_values[2])
        
        # Generate opacity variants
        for key, hex_color in palette.items():
            variables[f"{key}_80"] = self._hex_with_opacity(hex_color, 0.8)
            variables[f"{key}_60"] = self._hex_with_opacity(hex_color, 0.6)
            variables[f"{key}_40"] = self._hex_with_opacity(hex_color, 0.4)
            variables[f"{key}_20"] = self._hex_with_opacity(hex_color, 0.2)
        
        # Font variables (will be expanded in font management section)
        variables.update({
            "font_family": "JetBrains Mono",
            "font_size": "12",
            "font_size_large": "14",
            "font_size_small": "10",
            "icon_theme": "Papirus-Dark",
            "cursor_theme": "Adwaita",
            "gtk_theme": "Adwaita-dark",
        })
        
        return variables
    
    def _hex_to_rgb(self, hex_color: str) -> tuple:
        """Convert hex color to RGB tuple."""
        hex_color = hex_color.lstrip('#')
        return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))
    
    def _hex_with_opacity(self, hex_color: str, opacity: float) -> str:
        """Convert hex to hex with opacity (8-digit hex)."""
        alpha = int(opacity * 255)
        return f"{hex_color}{alpha:02x}"
    
    def _render_template_content(self, content: str, variables: Dict[str, str]) -> str:
        """Render template content by replacing variables."""
        
        # Replace {{variable_name}} patterns
        def replace_var(match):
            var_name = match.group(1)
            if var_name in variables:
                return variables[var_name]
            else:
                print(f"Warning: Unknown template variable: {var_name}")
                return match.group(0)  # Return original if not found
        
        rendered = re.sub(r'\{\{(\w+)\}\}', replace_var, content)
        
        # Replace ${variable_name} patterns (alternative syntax)
        def replace_env_var(match):
            var_name = match.group(1)
            if var_name in variables:
                return variables[var_name]
            else:
                print(f"Warning: Unknown template variable: {var_name}")
                return match.group(0)
        
        rendered = re.sub(r'\$\{(\w+)\}', replace_env_var, rendered)
        
        return rendered
    
    def _find_template_files(self) -> List[Path]:
        """Find all template files recursively."""
        template_files = []
        
        if self.templates_dir.exists():
            template_files = list(self.templates_dir.rglob("*.tmpl"))
        
        return sorted(template_files)
    
    def _get_output_path(self, template_path: Path) -> Path:
        """Get output path for rendered template."""
        # Remove .tmpl extension and preserve directory structure
        relative_path = template_path.relative_to(self.templates_dir)
        output_name = relative_path.name.replace('.tmpl', '')
        output_dir = self.rendered_dir / relative_path.parent
        
        # Create output directory
        output_dir.mkdir(parents=True, exist_ok=True)
        
        return output_dir / output_name
    
    def render_all_templates(self) -> Dict[str, str]:
        """Render all template files with current theme."""
        
        # Load current theme
        theme_data = self._load_current_theme()
        variables = self._get_template_variables(theme_data)
        
        print(f"Rendering templates with theme: {theme_data['wallpaper_name']}")
        
        # Find all template files
        template_files = self._find_template_files()
        
        if not template_files:
            print(f"No template files found in {self.templates_dir}")
            return {}
        
        rendered_files = {}
        
        # Render each template
        for template_path in template_files:
            try:
                print(f"Rendering {template_path.name}...")
                
                # Read template content
                with open(template_path, 'r') as f:
                    template_content = f.read()
                
                # Render template
                rendered_content = self._render_template_content(template_content, variables)
                
                # Get output path
                output_path = self._get_output_path(template_path)
                
                # Write rendered content
                with open(output_path, 'w') as f:
                    f.write(rendered_content)
                
                rendered_files[str(template_path)] = str(output_path)
                print(f"✓ Rendered to {output_path}")
                
            except Exception as e:
                print(f"✗ Error rendering {template_path}: {e}")
        
        print(f"Rendered {len(rendered_files)} template files")
        return rendered_files
    
    def get_rendered_file(self, app_name: str, file_name: str) -> Path:
        """Get path to specific rendered file."""
        return self.rendered_dir / app_name / file_name
    
    def clean_rendered_files(self) -> None:
        """Clean up previously rendered files."""
        if self.rendered_dir.exists():
            shutil.rmtree(self.rendered_dir)
            self.rendered_dir.mkdir(parents=True, exist_ok=True)
            print("Cleaned up old rendered files")

def main():
    """CLI entry point for template rendering."""
    import sys
    
    # Handle help request
    if len(sys.argv) > 1 and sys.argv[1] in ['--help', '-h', 'help']:
        print("Theme Template Renderer")
        print("Usage: python render_templates.py")
        print("")
        print("Renders all template files using current theme data.")
        print("Requires: theme_engine/theme_data/current.json")
        print("")
        print("Templates are rendered from config_templates/ to config_rendered/")
        return
    
    # Determine dotfiles directory
    script_dir = Path(__file__).parent
    dotfiles_dir = script_dir.parent
    
    try:
        # Render all templates
        renderer = ThemeRenderer(str(dotfiles_dir))
        renderer.render_all_templates()
        print("Templates rendered successfully")
    except FileNotFoundError as e:
        print(f"Error: {e}")
        print("Run apply_theme.sh first to generate theme data")
        sys.exit(1)

if __name__ == "__main__":
    main()
