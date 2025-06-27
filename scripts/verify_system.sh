#!/bin/bash
# scripts/verify_system.sh
# Comprehensive system verification script for the theming system

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source centralized logging
source "$DOTFILES_DIR/theme_engine/logger.sh"
log_script_start "$@"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

# Function to check requirement
check_requirement() {
    local name="$1"
    local command="$2"
    local type="${3:-command}"
    local critical="${4:-true}"
    
    case "$type" in
        "command")
            if command -v "$command" > /dev/null 2>&1; then
                log_success "VERIFY" "$name is available"
                echo -e "${GREEN}✓${NC} $name"
            else
                if [[ "$critical" == "true" ]]; then
                    log_error "VERIFY" "$name is missing (critical)"
                    echo -e "${RED}✗${NC} $name (CRITICAL)"
                    ((ERRORS++))
                else
                    log_warning "VERIFY" "$name is missing (optional)"
                    echo -e "${YELLOW}⚠${NC} $name (OPTIONAL)"
                    ((WARNINGS++))
                fi
            fi
            ;;
        "python")
            if python3 -c "import $command" 2>/dev/null; then
                log_success "VERIFY" "Python module $name is available"
                echo -e "${GREEN}✓${NC} Python: $name"
            else
                if [[ "$critical" == "true" ]]; then
                    log_error "VERIFY" "Python module $name is missing (critical)"
                    echo -e "${RED}✗${NC} Python: $name (CRITICAL)"
                    ((ERRORS++))
                else
                    log_warning "VERIFY" "Python module $name is missing (optional)"
                    echo -e "${YELLOW}⚠${NC} Python: $name (OPTIONAL)"
                    ((WARNINGS++))
                fi
            fi
            ;;
        "file")
            if [[ -f "$command" ]]; then
                log_success "VERIFY" "File $name exists"
                echo -e "${GREEN}✓${NC} File: $name"
            else
                if [[ "$critical" == "true" ]]; then
                    log_error "VERIFY" "File $name is missing (critical)"
                    echo -e "${RED}✗${NC} File: $name (CRITICAL)"
                    ((ERRORS++))
                else
                    log_warning "VERIFY" "File $name is missing (optional)"
                    echo -e "${YELLOW}⚠${NC} File: $name (OPTIONAL)"
                    ((WARNINGS++))
                fi
            fi
            ;;
        "directory")
            if [[ -d "$command" ]]; then
                log_success "VERIFY" "Directory $name exists"
                echo -e "${GREEN}✓${NC} Directory: $name"
            else
                if [[ "$critical" == "true" ]]; then
                    log_error "VERIFY" "Directory $name is missing (critical)"
                    echo -e "${RED}✗${NC} Directory: $name (CRITICAL)"
                    ((ERRORS++))
                else
                    log_warning "VERIFY" "Directory $name is missing (optional)"
                    echo -e "${YELLOW}⚠${NC} Directory: $name (OPTIONAL)"
                    ((WARNINGS++))
                fi
            fi
            ;;
    esac
}

# Function to check syntax
check_syntax() {
    local name="$1"
    local file="$2"
    local type="$3"
    
    case "$type" in
        "bash")
            if bash -n "$file" 2>/dev/null; then
                log_success "VERIFY" "Bash syntax OK: $name"
                echo -e "${GREEN}✓${NC} Bash syntax: $name"
            else
                log_error "VERIFY" "Bash syntax error: $name"
                echo -e "${RED}✗${NC} Bash syntax: $name"
                ((ERRORS++))
            fi
            ;;
        "python")
            if python3 -m py_compile "$file" 2>/dev/null; then
                log_success "VERIFY" "Python syntax OK: $name"
                echo -e "${GREEN}✓${NC} Python syntax: $name"
            else
                log_error "VERIFY" "Python syntax error: $name"
                echo -e "${RED}✗${NC} Python syntax: $name"
                ((ERRORS++))
            fi
            ;;
        "json")
            if python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
                log_success "VERIFY" "JSON syntax OK: $name"
                echo -e "${GREEN}✓${NC} JSON syntax: $name"
            else
                log_error "VERIFY" "JSON syntax error: $name"
                echo -e "${RED}✗${NC} JSON syntax: $name"
                ((ERRORS++))
            fi
            ;;
    esac
}

echo -e "${BOLD}${BLUE}Dynamic Theming System Verification${NC}"
echo "=================================="

# Check system requirements
echo -e "\n${BOLD}System Requirements:${NC}"
check_requirement "Hyprland" "hyprland"
check_requirement "Waybar" "waybar"
check_requirement "Rofi (Wayland)" "rofi"
check_requirement "Swww" "swww"
check_requirement "Dunst" "dunst"
check_requirement "Kitty" "kitty"
check_requirement "Foot" "foot"
check_requirement "Fish" "fish"
check_requirement "Btop" "btop"
check_requirement "GNU Stow" "stow"
check_requirement "ImageMagick" "convert"
check_requirement "Python 3" "python3"
check_requirement "Git" "git"
check_requirement "Curl" "curl"

# Check optional tools
echo -e "\n${BOLD}Optional Tools:${NC}"
check_requirement "Ollama" "ollama" "command" "false"
check_requirement "yay" "yay" "command" "false"
check_requirement "grim" "grim" "command" "false"
check_requirement "slurp" "slurp" "command" "false"
check_requirement "wl-clipboard" "wl-copy" "command" "false"

# Check Python modules
echo -e "\n${BOLD}Python Dependencies:${NC}"
check_requirement "requests" "requests" "python"
check_requirement "pathlib" "pathlib" "python"
check_requirement "json" "json" "python"
check_requirement "re" "re" "python"
check_requirement "base64" "base64" "python"
check_requirement "hashlib" "hashlib" "python"

# Check file structure
echo -e "\n${BOLD}File Structure:${NC}"
check_requirement "scripts directory" "$DOTFILES_DIR/scripts" "directory"
check_requirement "theme_engine directory" "$DOTFILES_DIR/theme_engine" "directory"
check_requirement "config_templates directory" "$DOTFILES_DIR/config_templates" "directory"
check_requirement "config_static directory" "$DOTFILES_DIR/config_static" "directory"
check_requirement "wallpapers directory" "$DOTFILES_DIR/wallpapers" "directory"

# Check core scripts
echo -e "\n${BOLD}Core Scripts:${NC}"
check_requirement "logger.sh" "$DOTFILES_DIR/theme_engine/logger.sh" "file"
check_requirement "wallpaper_picker.sh" "$DOTFILES_DIR/scripts/wallpaper_picker.sh" "file"
check_requirement "apply_theme.sh" "$DOTFILES_DIR/scripts/apply_theme.sh" "file"
check_requirement "extract_colors.py" "$DOTFILES_DIR/theme_engine/extract_colors.py" "file"
check_requirement "render_templates.py" "$DOTFILES_DIR/theme_engine/render_templates.py" "file"
check_requirement "merge_configs.py" "$DOTFILES_DIR/theme_engine/merge_configs.py" "file"
check_requirement "reload_apps.sh" "$DOTFILES_DIR/theme_engine/reload_apps.sh" "file"

# Check syntax
echo -e "\n${BOLD}Syntax Verification:${NC}"
check_syntax "wallpaper_picker.sh" "$DOTFILES_DIR/scripts/wallpaper_picker.sh" "bash"
check_syntax "apply_theme.sh" "$DOTFILES_DIR/scripts/apply_theme.sh" "bash"
check_syntax "reload_apps.sh" "$DOTFILES_DIR/theme_engine/reload_apps.sh" "bash"
check_syntax "setup_symlinks.sh" "$DOTFILES_DIR/scripts/setup_symlinks.sh" "bash"
check_syntax "install.sh" "$DOTFILES_DIR/install.sh" "bash"
check_syntax "logger.sh" "$DOTFILES_DIR/theme_engine/logger.sh" "bash"

check_syntax "extract_colors.py" "$DOTFILES_DIR/theme_engine/extract_colors.py" "python"
check_syntax "render_templates.py" "$DOTFILES_DIR/theme_engine/render_templates.py" "python"
check_syntax "merge_configs.py" "$DOTFILES_DIR/theme_engine/merge_configs.py" "python"

check_syntax "config-top.json" "$DOTFILES_DIR/config_static/waybar/config-top.json" "json"
check_syntax "config-bottom.json" "$DOTFILES_DIR/config_static/waybar/config-bottom.json" "json"

# Check permissions
echo -e "\n${BOLD}Script Permissions:${NC}"
for script in \
    "$DOTFILES_DIR/scripts/wallpaper_picker.sh" \
    "$DOTFILES_DIR/scripts/apply_theme.sh" \
    "$DOTFILES_DIR/scripts/setup_symlinks.sh" \
    "$DOTFILES_DIR/theme_engine/extract_colors.py" \
    "$DOTFILES_DIR/theme_engine/render_templates.py" \
    "$DOTFILES_DIR/theme_engine/merge_configs.py" \
    "$DOTFILES_DIR/theme_engine/reload_apps.sh" \
    "$DOTFILES_DIR/install.sh"; do
    
    if [[ -x "$script" ]]; then
        log_success "VERIFY" "$(basename "$script") is executable"
        echo -e "${GREEN}✓${NC} Executable: $(basename "$script")"
    else
        log_error "VERIFY" "$(basename "$script") is not executable"
        echo -e "${RED}✗${NC} Executable: $(basename "$script")"
        ((ERRORS++))
    fi
done

# Check Ollama service (if available)
echo -e "\n${BOLD}Ollama Service:${NC}"
if command -v ollama > /dev/null 2>&1; then
    if curl -s http://127.0.0.1:11434/api/tags > /dev/null 2>&1; then
        log_success "VERIFY" "Ollama service is running"
        echo -e "${GREEN}✓${NC} Ollama service is running"
        
        # Check for LLaVA model
        if ollama list | grep -q llava; then
            log_success "VERIFY" "LLaVA model is available"
            echo -e "${GREEN}✓${NC} LLaVA model available"
        else
            log_warning "VERIFY" "LLaVA model not found"
            echo -e "${YELLOW}⚠${NC} LLaVA model not found (run: ollama pull llava:latest)"
            ((WARNINGS++))
        fi
    else
        log_warning "VERIFY" "Ollama service not running"
        echo -e "${YELLOW}⚠${NC} Ollama service not running (will use fallback colors)"
        ((WARNINGS++))
    fi
else
    log_warning "VERIFY" "Ollama not installed"
    echo -e "${YELLOW}⚠${NC} Ollama not installed (will use fallback colors)"
    ((WARNINGS++))
fi

# Check graphics
echo -e "\n${BOLD}Graphics Hardware:${NC}"
if lspci | grep -i amd > /dev/null; then
    log_success "VERIFY" "AMD GPU detected (AMDGPU optimizations available)"
    echo -e "${GREEN}✓${NC} AMD GPU detected"
else
    log_warning "VERIFY" "AMD GPU not detected"
    echo -e "${YELLOW}⚠${NC} AMD GPU not detected (AMDGPU optimizations unavailable)"
    ((WARNINGS++))
fi

# Summary
echo -e "\n${BOLD}Verification Summary:${NC}"
echo "==================="

if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
    log_success "VERIFY" "All checks passed! System is ready."
    echo -e "${GREEN}✓ All checks passed! System is ready.${NC}"
elif [[ $ERRORS -eq 0 ]]; then
    log_warning "VERIFY" "$WARNINGS warnings found, but system should work"
    echo -e "${YELLOW}⚠ $WARNINGS warnings found, but system should work${NC}"
else
    log_error "VERIFY" "$ERRORS errors and $WARNINGS warnings found"
    echo -e "${RED}✗ $ERRORS errors and $WARNINGS warnings found${NC}"
    echo -e "${RED}Please fix the errors before using the system${NC}"
fi

echo
echo "Log file: $LOG_FILE"
echo "View logs: tail -f $LOG_FILE"

exit $ERRORS

# Ensure proper exit logging
trap 'log_script_end $?' EXIT