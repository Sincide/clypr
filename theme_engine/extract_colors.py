#!/usr/bin/env python3
# theme_engine/extract_colors.py
# LLaVA color extraction via Ollama API for MaterialYou theming
# Requires: ollama, llava model

import json
import os
import sys
import hashlib
import requests
import base64
import subprocess
import time
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import re

# Setup logging to central file
def log_to_file(level: str, component: str, message: str):
    """Log messages to central log file using bash logger"""
    try:
        subprocess.run([
            'bash', '-c', 
            f'source "{Path(__file__).parent}/logger.sh" && log_{level.lower()} "{component}" "{message}"'
        ], check=False, capture_output=True)
    except Exception:
        pass  # Fallback to stderr if logging fails

def log_info(component: str, message: str):
    log_to_file("INFO", component, message)
    print(f"[INFO] [{component}] {message}")

def log_error(component: str, message: str):
    log_to_file("ERROR", component, message)
    print(f"[ERROR] [{component}] {message}", file=sys.stderr)

def log_success(component: str, message: str):
    log_to_file("SUCCESS", component, message)
    print(f"[SUCCESS] [{component}] ✓ {message}")

def log_warning(component: str, message: str):
    log_to_file("WARNING", component, message)
    print(f"[WARNING] [{component}] ⚠ {message}")

def log_debug(component: str, message: str):
    log_to_file("DEBUG", component, message)
    if os.getenv("DEBUG"):
        print(f"[DEBUG] [{component}] {message}")

class ColorExtractor:
    """Extracts MaterialYou color palette from wallpapers using LLaVA via Ollama."""
    
    def __init__(self, dotfiles_dir: str):
        self.dotfiles_dir = Path(dotfiles_dir)
        self.cache_dir = self.dotfiles_dir / "theme_engine" / "theme_data" / "palette_cache"
        self.current_theme_file = self.dotfiles_dir / "theme_engine" / "theme_data" / "current.json"
        self.ollama_url = "http://127.0.0.1:11434"  # Default Ollama API URL
        self.model = "llava:latest"  # LLaVA model name
        
        # Create cache directory if it doesn't exist
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.current_theme_file.parent.mkdir(parents=True, exist_ok=True)
    
    def _get_wallpaper_hash(self, wallpaper_path: str) -> str:
        """Generate SHA256 hash of wallpaper file for caching."""
        with open(wallpaper_path, 'rb') as f:
            return hashlib.sha256(f.read()).hexdigest()[:16]
    
    def _encode_image(self, image_path: str) -> str:
        """Encode image to base64 for Ollama API."""
        with open(image_path, 'rb') as f:
            return base64.b64encode(f.read()).decode('utf-8')
    
    def _check_ollama_available(self) -> bool:
        """Check if Ollama service is running and model is available."""
        try:
            # Check if Ollama is running
            response = requests.get(f"{self.ollama_url}/api/tags", timeout=5)
            if response.status_code != 200:
                return False
            
            # Check if LLaVA model is available
            models = response.json().get("models", [])
            for model in models:
                if model.get("name", "").startswith("llava"):
                    self.model = model["name"]
                    return True
            
            log_error("OLLAMA", f"LLaVA model not found. Available models: {[m['name'] for m in models]}")
            return False
            
        except requests.exceptions.RequestException as e:
            log_error("OLLAMA", f"Ollama service not available: {e}")
            return False
    
    def _call_llava(self, image_path: str) -> Optional[Dict]:
        """Call LLaVA via Ollama API to extract colors from image."""
        
        # LLaVA prompt for MaterialYou color extraction
        prompt = """Analyze this wallpaper image and extract a MaterialYou color palette. 
        Return ONLY a JSON object with these exact keys, no additional text:

        {
            "primary": "#RRGGBB",
            "secondary": "#RRGGBB", 
            "tertiary": "#RRGGBB",
            "background": "#RRGGBB",
            "surface": "#RRGGBB",
            "accent": "#RRGGBB",
            "text_primary": "#RRGGBB",
            "text_secondary": "#RRGGBB",
            "text_accent": "#RRGGBB"
        }

        Rules:
        - Use the most prominent/dominant colors from the image
        - Ensure good contrast ratios for text colors
        - Background should be dark if image is dark, light if image is light
        - All colors must be valid 6-digit hex codes
        - Primary should be the most prominent color
        - Secondary should complement primary
        - Accent should be vibrant and stand out
        - Text colors should contrast well with backgrounds"""
        
        try:
            # Encode image
            image_base64 = self._encode_image(image_path)
            
            # Prepare Ollama API request
            payload = {
                "model": self.model,
                "prompt": prompt,
                "images": [image_base64],
                "stream": False,
                "options": {
                    "temperature": 0.1,  # Low temperature for consistent output
                    "num_predict": 200   # Limit response length
                }
            }
            
            print(f"Calling LLaVA model '{self.model}' for color extraction...")
            
            # Make API call
            response = requests.post(
                f"{self.ollama_url}/api/generate",
                json=payload,
                timeout=60  # 60 second timeout for image processing
            )
            
            if response.status_code != 200:
                print(f"Ollama API error: {response.status_code} - {response.text}")
                return None
            
            # Parse response
            result = response.json()
            response_text = result.get("response", "").strip()
            
            print(f"LLaVA response: {response_text}")
            
            # Extract JSON from response
            json_match = re.search(r'\{[^}]*\}', response_text, re.DOTALL)
            if not json_match:
                print("No JSON found in LLaVA response")
                return None
            
            # Parse JSON
            color_data = json.loads(json_match.group())
            
            # Validate color format
            if not self._validate_color_palette(color_data):
                print("Invalid color palette format from LLaVA")
                return None
            
            return color_data
            
        except requests.exceptions.RequestException as e:
            print(f"Error calling Ollama API: {e}")
            return None
        except json.JSONDecodeError as e:
            print(f"Error parsing LLaVA JSON response: {e}")
            return None
        except Exception as e:
            print(f"Unexpected error in LLaVA call: {e}")
            return None
    
    def _validate_color_palette(self, palette: Dict) -> bool:
        """Validate that color palette has required keys and valid hex colors."""
        required_keys = [
            "primary", "secondary", "tertiary", "background", 
            "surface", "accent", "text_primary", "text_secondary", "text_accent"
        ]
        
        # Check all required keys present
        if not all(key in palette for key in required_keys):
            missing = [key for key in required_keys if key not in palette]
            print(f"Missing color keys: {missing}")
            return False
        
        # Validate hex color format
        hex_pattern = re.compile(r'^#[0-9A-Fa-f]{6}$')
        for key, color in palette.items():
            if not hex_pattern.match(str(color)):
                print(f"Invalid hex color for {key}: {color}")
                return False
        
        return True
    
    def _generate_fallback_palette(self, wallpaper_path: str) -> Dict:
        """Generate a fallback color palette when LLaVA fails."""
        print("Generating fallback color palette...")
        
        # Simple fallback based on file name or use default dark theme
        return {
            "primary": "#89b4fa",      # Catppuccin blue
            "secondary": "#cba6f7",    # Catppuccin mauve  
            "tertiary": "#f38ba8",     # Catppuccin pink
            "background": "#1e1e2e",   # Catppuccin base
            "surface": "#313244",      # Catppuccin surface0
            "accent": "#a6e3a1",       # Catppuccin green
            "text_primary": "#cdd6f4", # Catppuccin text
            "text_secondary": "#bac2de", # Catppuccin subtext1
            "text_accent": "#f9e2af"   # Catppuccin yellow
        }
    
    def _save_to_cache(self, wallpaper_hash: str, palette: Dict) -> None:
        """Save extracted palette to cache."""
        cache_file = self.cache_dir / f"{wallpaper_hash}.json"
        
        cache_data = {
            "wallpaper_hash": wallpaper_hash,
            "palette": palette,
            "extracted_at": __import__('time').time()
        }
        
        with open(cache_file, 'w') as f:
            json.dump(cache_data, f, indent=2)
        
        print(f"Cached palette for hash {wallpaper_hash}")
    
    def _load_from_cache(self, wallpaper_hash: str) -> Optional[Dict]:
        """Load palette from cache if available."""
        cache_file = self.cache_dir / f"{wallpaper_hash}.json"
        
        if cache_file.exists():
            try:
                with open(cache_file, 'r') as f:
                    cache_data = json.load(f)
                
                palette = cache_data.get("palette")
                if palette and self._validate_color_palette(palette):
                    print(f"Using cached palette for hash {wallpaper_hash}")
                    return palette
                    
            except (json.JSONDecodeError, KeyError) as e:
                print(f"Error loading cache file {cache_file}: {e}")
                # Remove corrupted cache file
                cache_file.unlink(missing_ok=True)
        
        return None
    
    def _save_current_theme(self, wallpaper_path: str, palette: Dict) -> None:
        """Save current theme data to current.json."""
        theme_data = {
            "wallpaper_path": str(wallpaper_path),
            "wallpaper_name": os.path.basename(wallpaper_path),
            "palette": palette,
            "applied_at": __import__('time').time(),
            "version": "1.0"
        }
        
        with open(self.current_theme_file, 'w') as f:
            json.dump(theme_data, f, indent=2)
        
        print(f"Current theme saved to {self.current_theme_file}")
    
    def extract_colors(self, wallpaper_path: str) -> Dict:
        """Main method to extract colors from wallpaper."""
        
        if not os.path.exists(wallpaper_path):
            print(f"Wallpaper file not found: {wallpaper_path}")
            return self._generate_fallback_palette(wallpaper_path)
        
        # Generate hash for caching
        wallpaper_hash = self._get_wallpaper_hash(wallpaper_path)
        
        # Try to load from cache first
        cached_palette = self._load_from_cache(wallpaper_hash)
        if cached_palette:
            self._save_current_theme(wallpaper_path, cached_palette)
            return cached_palette
        
        # Check if Ollama is available
        if not self._check_ollama_available():
            print("Ollama/LLaVA not available, using fallback palette")
            fallback_palette = self._generate_fallback_palette(wallpaper_path)
            self._save_current_theme(wallpaper_path, fallback_palette)
            return fallback_palette
        
        # Extract colors using LLaVA
        palette = self._call_llava(wallpaper_path)
        
        if not palette:
            print("LLaVA extraction failed, using fallback palette")
            palette = self._generate_fallback_palette(wallpaper_path)
        else:
            print("Successfully extracted colors with LLaVA")
            # Cache the extracted palette
            self._save_to_cache(wallpaper_hash, palette)
        
        # Save as current theme
        self._save_current_theme(wallpaper_path, palette)
        
        return palette

def main():
    """CLI entry point for color extraction."""
    if len(sys.argv) != 2:
        print("Usage: extract_colors.py <wallpaper_path>")
        sys.exit(1)
    
    wallpaper_path = sys.argv[1]
    
    # Determine dotfiles directory (parent of theme_engine)
    script_dir = Path(__file__).parent
    dotfiles_dir = script_dir.parent
    
    # Extract colors
    extractor = ColorExtractor(str(dotfiles_dir))
    palette = extractor.extract_colors(wallpaper_path)
    
    # Print palette as JSON
    print(json.dumps(palette, indent=2))

if __name__ == "__main__":
    main()