#!/bin/bash
# theme_engine/logger.sh
# Centralized logging system for all theming operations

# Global log file
LOG_FILE="${HOME}/.local/share/clypr/theme.log"
LOG_DIR="$(dirname "$LOG_FILE")"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Log rotation settings
MAX_LOG_SIZE=10485760  # 10MB
MAX_LOG_FILES=5

# Colors for terminal output (when not redirected)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Function to rotate logs if they get too large
rotate_log() {
    if [[ -f "$LOG_FILE" && $(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null || echo 0) -gt $MAX_LOG_SIZE ]]; then
        # Rotate existing logs
        for i in $(seq $((MAX_LOG_FILES-1)) -1 1); do
            if [[ -f "${LOG_FILE}.$i" ]]; then
                mv "${LOG_FILE}.$i" "${LOG_FILE}.$((i+1))"
            fi
        done
        
        # Move current log to .1
        mv "$LOG_FILE" "${LOG_FILE}.1"
        
        # Create new log file
        touch "$LOG_FILE"
    fi
}

# Function to write to log with timestamp and context
write_log() {
    local level="$1"
    local component="$2"
    local message="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local caller_info=""
    
    # Get caller information
    if [[ -n "${BASH_SOURCE[2]:-}" ]]; then
        local script_name=$(basename "${BASH_SOURCE[2]}")
        local line_number="${BASH_LINENO[1]}"
        caller_info="[$script_name:$line_number]"
    fi
    
    # Rotate log if needed
    rotate_log
    
    # Write to log file
    echo "$timestamp [$level] [$component] $caller_info $message" >> "$LOG_FILE"
}

# Logging functions with both terminal and file output
log_info() {
    local component="${1:-SYSTEM}"
    local message="$2"
    write_log "INFO" "$component" "$message"
    if [[ -t 1 ]]; then  # Only show colors if outputting to terminal
        echo -e "${BLUE}[INFO]${NC} [$component] $message"
    else
        echo "[INFO] [$component] $message"
    fi
}

log_success() {
    local component="${1:-SYSTEM}"
    local message="$2"
    write_log "SUCCESS" "$component" "$message"
    if [[ -t 1 ]]; then
        echo -e "${GREEN}[SUCCESS]${NC} [$component] ✓ $message"
    else
        echo "[SUCCESS] [$component] ✓ $message"
    fi
}

log_warning() {
    local component="${1:-SYSTEM}"
    local message="$2"
    write_log "WARNING" "$component" "$message"
    if [[ -t 1 ]]; then
        echo -e "${YELLOW}[WARNING]${NC} [$component] ⚠ $message"
    else
        echo "[WARNING] [$component] ⚠ $message"
    fi
}

log_error() {
    local component="${1:-SYSTEM}"
    local message="$2"
    write_log "ERROR" "$component" "$message"
    if [[ -t 1 ]]; then
        echo -e "${RED}[ERROR]${NC} [$component] ✗ $message" >&2
    else
        echo "[ERROR] [$component] ✗ $message" >&2
    fi
}

log_debug() {
    local component="${1:-SYSTEM}"
    local message="$2"
    write_log "DEBUG" "$component" "$message"
    # Debug messages only go to log file, not terminal (unless DEBUG env var is set)
    if [[ -n "${DEBUG:-}" && -t 1 ]]; then
        echo -e "${PURPLE}[DEBUG]${NC} [$component] $message"
    fi
}

log_command() {
    local component="${1:-COMMAND}"
    local command="$2"
    local description="${3:-}"
    
    write_log "COMMAND" "$component" "Executing: $command ${description:+($description)}"
    
    if [[ -t 1 ]]; then
        echo -e "${CYAN}[COMMAND]${NC} [$component] $command ${description:+($description)}"
    else
        echo "[COMMAND] [$component] $command ${description:+($description)}"
    fi
}

# Function to log script start
log_script_start() {
    local script_name="$(basename "${BASH_SOURCE[1]}")"
    local args="$*"
    
    write_log "START" "SCRIPT" "$script_name started with args: $args"
    write_log "SYSTEM" "ENV" "USER=$USER, PWD=$PWD, SHELL=$SHELL"
    write_log "SYSTEM" "ENV" "PATH=$PATH"
    
    if [[ -t 1 ]]; then
        echo -e "${BOLD}${BLUE}[START]${NC} $script_name $args"
    fi
}

# Function to log script end
log_script_end() {
    local script_name="$(basename "${BASH_SOURCE[1]}")"
    local exit_code="${1:-0}"
    
    if [[ $exit_code -eq 0 ]]; then
        write_log "END" "SCRIPT" "$script_name completed successfully"
        if [[ -t 1 ]]; then
            echo -e "${BOLD}${GREEN}[END]${NC} $script_name completed successfully"
        fi
    else
        write_log "END" "SCRIPT" "$script_name failed with exit code $exit_code"
        if [[ -t 1 ]]; then
            echo -e "${BOLD}${RED}[END]${NC} $script_name failed with exit code $exit_code"
        fi
    fi
}

# Function to log Python errors
log_python_error() {
    local component="$1"
    local error_output="$2"
    
    write_log "ERROR" "$component" "Python error occurred:"
    echo "$error_output" | while IFS= read -r line; do
        write_log "ERROR" "$component" "  $line"
    done
}

# Function to show log file location
show_log_info() {
    echo "Centralized logging enabled:"
    echo "  Log file: $LOG_FILE"
    echo "  Log size: $(du -h "$LOG_FILE" 2>/dev/null | cut -f1 || echo "0B")"
    echo "  View logs: tail -f $LOG_FILE"
    echo "  Debug mode: export DEBUG=1"
}

# Function to tail logs with colors
tail_logs() {
    local lines="${1:-50}"
    
    if [[ ! -f "$LOG_FILE" ]]; then
        echo "No log file found at $LOG_FILE"
        return 1
    fi
    
    echo "Last $lines lines from theme log:"
    echo "================================="
    
    tail -n "$lines" "$LOG_FILE" | while IFS= read -r line; do
        if [[ $line =~ \[ERROR\] ]]; then
            echo -e "${RED}$line${NC}"
        elif [[ $line =~ \[WARNING\] ]]; then
            echo -e "${YELLOW}$line${NC}"
        elif [[ $line =~ \[SUCCESS\] ]]; then
            echo -e "${GREEN}$line${NC}"
        elif [[ $line =~ \[DEBUG\] ]]; then
            echo -e "${PURPLE}$line${NC}"
        elif [[ $line =~ \[COMMAND\] ]]; then
            echo -e "${CYAN}$line${NC}"
        else
            echo "$line"
        fi
    done
}

# Function to clear logs
clear_logs() {
    local confirm="${1:-}"
    
    if [[ "$confirm" != "--force" ]]; then
        echo "This will delete all log files. Current log size: $(du -h "$LOG_FILE" 2>/dev/null | cut -f1 || echo "0B")"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Log clearing cancelled"
            return 0
        fi
    fi
    
    # Remove all log files
    rm -f "$LOG_FILE"*
    echo "All log files cleared"
    
    # Create new empty log
    touch "$LOG_FILE"
    write_log "SYSTEM" "LOGGER" "Log files cleared and reinitialized"
}

# Export functions for use in other scripts
export -f write_log log_info log_success log_warning log_error log_debug
export -f log_command log_script_start log_script_end log_python_error
export -f show_log_info tail_logs clear_logs
export LOG_FILE LOG_DIR

# Initialize log file on first source
if [[ ! -f "$LOG_FILE" ]]; then
    touch "$LOG_FILE"
    write_log "SYSTEM" "LOGGER" "Centralized logging system initialized"
fi