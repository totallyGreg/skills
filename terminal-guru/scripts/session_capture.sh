#!/bin/bash
# Session Capture Tool for Terminal Debugging
# Records terminal sessions with timing information for replay

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSIONS_DIR="${SESSIONS_DIR:-$HOME/.terminal-guru/sessions}"
mkdir -p "$SESSIONS_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] COMMAND

Capture terminal session for debugging terminal issues.

OPTIONS:
    -n, --name NAME          Session name (default: auto-generated)
    -d, --description DESC   Description of the issue
    -m, --minimal-config     Use minimal zsh configuration
    -t, --tmux              Run in isolated tmux session
    -h, --help              Show this help

COMMANDS:
    start [NAME]            Start recording a session
    stop                    Stop current recording
    list                    List all recorded sessions
    show NAME               Show session details
    replay NAME             Replay a recorded session
    compare NAME1 NAME2     Compare two sessions
    clean [NAME]            Delete session(s)

EXAMPLES:
    # Start recording with auto-generated name
    $(basename "$0") start

    # Start recording with specific name and description
    $(basename "$0") -n unicode-issue -d "Emoji backspace problem" start

    # Record in isolated tmux with minimal config
    $(basename "$0") -t -m -n test-session start

    # Replay a session
    $(basename "$0") replay unicode-issue

    # Compare sessions (before/after fix)
    $(basename "$0") compare unicode-before unicode-after

EOF
    exit 1
}

generate_session_name() {
    echo "session-$(date +%Y%m%d-%H%M%S)"
}

start_recording() {
    local session_name="${1:-$(generate_session_name)}"
    local session_dir="$SESSIONS_DIR/$session_name"
    
    if [[ -d "$session_dir" ]]; then
        echo -e "${RED}Error: Session '$session_name' already exists${NC}"
        exit 1
    fi
    
    mkdir -p "$session_dir"
    
    # Save metadata
    cat > "$session_dir/metadata.json" << EOF
{
    "name": "$session_name",
    "description": "${DESCRIPTION:-No description}",
    "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "hostname": "$(hostname)",
    "user": "$USER",
    "term": "$TERM",
    "shell": "$SHELL",
    "minimal_config": ${MINIMAL_CONFIG:-false},
    "tmux_isolated": ${USE_TMUX:-false}
}
EOF
    
    # Capture environment
    env > "$session_dir/environment.txt"
    locale > "$session_dir/locale.txt"
    
    # Capture diagnostics
    if command -v python3 &>/dev/null && [[ -f "$SCRIPT_DIR/terminal_diagnostics.py" ]]; then
        python3 "$SCRIPT_DIR/terminal_diagnostics.py" > "$session_dir/diagnostics.txt" 2>&1 || true
    fi
    
    echo -e "${GREEN}Starting session recording: $session_name${NC}"
    echo -e "${BLUE}Session directory: $session_dir${NC}"
    echo
    
    if [[ "$USE_TMUX" == "true" ]]; then
        start_tmux_session "$session_name" "$session_dir"
    else
        start_script_session "$session_name" "$session_dir"
    fi
}

start_script_session() {
    local session_name="$1"
    local session_dir="$2"
    
    echo -e "${YELLOW}Recording started. Type 'exit' or Ctrl+D to stop.${NC}"
    echo
    
    # Use script command to record session with timing
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS version
        script -q -t 0 "$session_dir/typescript" 2>"$session_dir/timing.txt"
    else
        # Linux version
        script -q -t "$session_dir/timing.txt" "$session_dir/typescript"
    fi
    
    echo
    echo -e "${GREEN}Session recording saved: $session_name${NC}"
    echo -e "${BLUE}To replay: $(basename "$0") replay $session_name${NC}"
}

start_tmux_session() {
    local session_name="$1"
    local session_dir="$2"
    
    # Create tmux config for this session
    local tmux_config="$session_dir/tmux.conf"
    cat > "$tmux_config" << 'EOF'
# Minimal tmux configuration for testing
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"

# Enable mouse for easier testing
set -g mouse on

# Status bar
set -g status-style bg=colour235,fg=colour136
set -g status-left "#[fg=green]Session: #S | "
set -g status-right "#[fg=yellow]Testing Mode"

# Longer history
set -g history-limit 10000
EOF
    
    # Create zsh config if using minimal config
    if [[ "$MINIMAL_CONFIG" == "true" ]]; then
        create_minimal_zshrc "$session_dir"
    fi
    
    # Start tmux with pipe-pane to capture output
    local tmux_session="tg-$session_name"
    
    echo -e "${YELLOW}Starting isolated tmux session: $tmux_session${NC}"
    echo -e "${YELLOW}Recording to: $session_dir/typescript${NC}"
    echo
    
    # Create a script to run inside tmux
    cat > "$session_dir/run.sh" << EOF
#!/bin/bash
export TERM=tmux-256color
$(if [[ "$MINIMAL_CONFIG" == "true" ]]; then
    echo "export ZDOTDIR=$session_dir"
fi)
exec $SHELL
EOF
    chmod +x "$session_dir/run.sh"
    
    # Start tmux session with logging
    tmux -f "$tmux_config" new-session -s "$tmux_session" \
        "tmux pipe-pane -o 'cat >> $session_dir/typescript'; $session_dir/run.sh"
    
    echo
    echo -e "${GREEN}Session recording saved: $session_name${NC}"
    echo -e "${BLUE}To replay: $(basename "$0") replay $session_name${NC}"
}

create_minimal_zshrc() {
    local session_dir="$1"
    
    cat > "$session_dir/.zshenv" << 'EOF'
# Minimal zsh environment for testing
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
EOF
    
    cat > "$session_dir/.zshrc" << 'EOF'
# Minimal zshrc for terminal testing
# No plugins, no fancy prompts - just basics

# Basic prompt
PS1='%F{green}test%f %F{blue}%~%f %# '

# Basic history
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000

# Basic completion
autoload -Uz compinit
compinit

# Useful aliases for testing
alias ll='ls -lah'
alias reload='exec zsh'

# Show that minimal config is loaded
echo "Minimal zsh configuration loaded for testing"
EOF

    cat > "$session_dir/.zprofile" << 'EOF'
# Minimal zprofile
EOF
}

list_sessions() {
    echo -e "${BLUE}Recorded Sessions:${NC}"
    echo
    
    if [[ ! -d "$SESSIONS_DIR" ]] || [[ -z "$(ls -A "$SESSIONS_DIR" 2>/dev/null)" ]]; then
        echo "No sessions found."
        return
    fi
    
    printf "%-30s %-20s %-s\n" "NAME" "DATE" "DESCRIPTION"
    echo "──────────────────────────────────────────────────────────────────────"
    
    for session_dir in "$SESSIONS_DIR"/*; do
        if [[ -f "$session_dir/metadata.json" ]]; then
            local name=$(basename "$session_dir")
            local created=$(jq -r '.created // "unknown"' "$session_dir/metadata.json" 2>/dev/null || echo "unknown")
            local desc=$(jq -r '.description // ""' "$session_dir/metadata.json" 2>/dev/null || echo "")
            printf "%-30s %-20s %-s\n" "$name" "$created" "$desc"
        fi
    done
}

show_session() {
    local session_name="$1"
    local session_dir="$SESSIONS_DIR/$session_name"
    
    if [[ ! -d "$session_dir" ]]; then
        echo -e "${RED}Error: Session '$session_name' not found${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Session: $session_name${NC}"
    echo
    
    if [[ -f "$session_dir/metadata.json" ]]; then
        echo -e "${YELLOW}Metadata:${NC}"
        jq '.' "$session_dir/metadata.json" 2>/dev/null || cat "$session_dir/metadata.json"
        echo
    fi
    
    echo -e "${YELLOW}Files:${NC}"
    ls -lh "$session_dir"
    echo
    
    if [[ -f "$session_dir/diagnostics.txt" ]]; then
        echo -e "${YELLOW}Diagnostics available. View with:${NC}"
        echo "  cat $session_dir/diagnostics.txt"
        echo
    fi
}

replay_session() {
    local session_name="$1"
    local session_dir="$SESSIONS_DIR/$session_name"
    
    if [[ ! -d "$session_dir" ]]; then
        echo -e "${RED}Error: Session '$session_name' not found${NC}"
        exit 1
    fi
    
    if [[ ! -f "$session_dir/typescript" ]]; then
        echo -e "${RED}Error: No typescript file found for session '$session_name'${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Replaying session: $session_name${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    echo
    
    if [[ -f "$session_dir/timing.txt" ]] && command -v scriptreplay &>/dev/null; then
        # Replay with timing
        scriptreplay -t "$session_dir/timing.txt" -s "$session_dir/typescript"
    else
        # Just cat the output
        echo -e "${YELLOW}(Timing not available, showing full output)${NC}"
        echo
        cat "$session_dir/typescript"
    fi
}

compare_sessions() {
    local session1="$1"
    local session2="$2"
    
    local dir1="$SESSIONS_DIR/$session1"
    local dir2="$SESSIONS_DIR/$session2"
    
    if [[ ! -d "$dir1" ]]; then
        echo -e "${RED}Error: Session '$session1' not found${NC}"
        exit 1
    fi
    
    if [[ ! -d "$dir2" ]]; then
        echo -e "${RED}Error: Session '$session2' not found${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Comparing sessions: $session1 vs $session2${NC}"
    echo
    
    # Compare environments
    echo -e "${YELLOW}Environment Differences:${NC}"
    diff -u "$dir1/environment.txt" "$dir2/environment.txt" || true
    echo
    
    # Compare locales
    echo -e "${YELLOW}Locale Differences:${NC}"
    diff -u "$dir1/locale.txt" "$dir2/locale.txt" || true
    echo
    
    # Compare diagnostics if available
    if [[ -f "$dir1/diagnostics.txt" ]] && [[ -f "$dir2/diagnostics.txt" ]]; then
        echo -e "${YELLOW}Diagnostics Differences:${NC}"
        diff -u "$dir1/diagnostics.txt" "$dir2/diagnostics.txt" || true
        echo
    fi
    
    # Compare metadata
    echo -e "${YELLOW}Metadata Comparison:${NC}"
    echo "Session 1: $session1"
    jq '.' "$dir1/metadata.json" 2>/dev/null
    echo
    echo "Session 2: $session2"
    jq '.' "$dir2/metadata.json" 2>/dev/null
}

clean_sessions() {
    local session_name="$1"
    
    if [[ -z "$session_name" ]]; then
        # Clean all sessions
        read -p "Delete all sessions? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$SESSIONS_DIR"/*
            echo -e "${GREEN}All sessions deleted${NC}"
        fi
    else
        # Clean specific session
        local session_dir="$SESSIONS_DIR/$session_name"
        if [[ -d "$session_dir" ]]; then
            rm -rf "$session_dir"
            echo -e "${GREEN}Session '$session_name' deleted${NC}"
        else
            echo -e "${RED}Error: Session '$session_name' not found${NC}"
            exit 1
        fi
    fi
}

# Parse options
MINIMAL_CONFIG=false
USE_TMUX=false
DESCRIPTION=""
SESSION_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            SESSION_NAME="$2"
            shift 2
            ;;
        -d|--description)
            DESCRIPTION="$2"
            shift 2
            ;;
        -m|--minimal-config)
            MINIMAL_CONFIG=true
            shift
            ;;
        -t|--tmux)
            USE_TMUX=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        start)
            start_recording "$SESSION_NAME"
            exit 0
            ;;
        stop)
            echo "Session stopped (exit the shell)"
            exit 0
            ;;
        list)
            list_sessions
            exit 0
            ;;
        show)
            show_session "$2"
            exit 0
            ;;
        replay)
            replay_session "$2"
            exit 0
            ;;
        compare)
            compare_sessions "$2" "$3"
            exit 0
            ;;
        clean)
            clean_sessions "$2"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

usage
