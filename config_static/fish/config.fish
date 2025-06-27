# ~/.config/fish/config.fish
# Fish shell configuration

# Disable fish greeting
set fish_greeting

# Set default editor
set -gx EDITOR nvim

# Set browser
set -gx BROWSER brave

# Add ~/.local/bin to PATH if it exists
if test -d ~/.local/bin
    set -gx PATH ~/.local/bin $PATH
end

# Add cargo bin to PATH if it exists
if test -d ~/.cargo/bin
    set -gx PATH ~/.cargo/bin $PATH
end

# Set XDG directories
set -gx XDG_CONFIG_HOME ~/.config
set -gx XDG_DATA_HOME ~/.local/share
set -gx XDG_CACHE_HOME ~/.cache

# Wayland environment variables
set -gx XDG_SESSION_TYPE wayland
set -gx XDG_CURRENT_DESKTOP Hyprland
set -gx QT_QPA_PLATFORM wayland
set -gx GDK_BACKEND wayland
set -gx SDL_VIDEODRIVER wayland
set -gx CLUTTER_BACKEND wayland

# Fix Java applications in Wayland
set -gx _JAVA_AWT_WM_NONREPARENTING 1

# AMD GPU environment
set -gx HSA_OVERRIDE_GFX_VERSION 10.3.0
set -gx ROCM_PATH /opt/rocm

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias cls='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias tree='tree -C'
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# Git aliases
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# System aliases
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps aux'
alias top='btop'

# Package management
alias pacman='sudo pacman'
alias yay='yay --noconfirm'
alias update='yay -Syu'
alias install='yay -S'
alias remove='yay -Rs'
alias search='yay -Ss'

# Clypr aliases
alias theme-apply='~/clypr/scripts/apply_theme.sh'
alias theme-picker='~/clypr/scripts/wallpaper_picker.sh'
alias theme-restore='~/clypr/scripts/apply_theme.sh restore'

# Functions
function mkcd
    mkdir -p $argv[1] && cd $argv[1]
end

function extract
    if test -f $argv[1]
        switch $argv[1]
            case '*.tar.bz2'
                tar xjf $argv[1]
            case '*.tar.gz'
                tar xzf $argv[1]
            case '*.bz2'
                bunzip2 $argv[1]
            case '*.rar'
                unrar x $argv[1]
            case '*.gz'
                gunzip $argv[1]
            case '*.tar'
                tar xf $argv[1]
            case '*.tbz2'
                tar xjf $argv[1]
            case '*.tgz'
                tar xzf $argv[1]
            case '*.zip'
                unzip $argv[1]
            case '*.Z'
                uncompress $argv[1]
            case '*.7z'
                7z x $argv[1]
            case '*'
                echo "'$argv[1]' cannot be extracted via extract()"
        end
    else
        echo "'$argv[1]' is not a valid file"
    end
end

# Fish syntax highlighting colors (will be overridden by theme)
set fish_color_normal normal
set fish_color_command blue
set fish_color_quote yellow
set fish_color_redirection cyan
set fish_color_end green
set fish_color_error red
set fish_color_param normal
set fish_color_comment brblack
set fish_color_match --background=brblue
set fish_color_selection white --bold --background=brblack
set fish_color_search_match bryellow --background=brblack
set fish_color_history_current --bold
set fish_color_operator cyan
set fish_color_escape brcyan
set fish_color_cwd green
set fish_color_cwd_root red
set fish_color_valid_path --underline
set fish_color_autosuggestion brblack
set fish_color_user brgreen
set fish_color_host normal
set fish_color_cancel -r
set fish_pager_color_completion normal
set fish_pager_color_description B3A06D yellow
set fish_pager_color_prefix white --bold --underline
set fish_pager_color_progress brwhite --background=cyan

# Load theme colors if available
if test -f ~/.config/fish/theme.fish
    source ~/.config/fish/theme.fish
end

# Vi mode
fish_vi_key_bindings

# Auto-completion for common tools
if command -v kubectl >/dev/null
    kubectl completion fish | source
end

if command -v helm >/dev/null
    helm completion fish | source
end