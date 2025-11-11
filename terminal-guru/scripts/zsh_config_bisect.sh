#!/bin/bash
# Zsh Configuration Bisection Tool
# Test your config systematically by enabling/disabling components

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="${TEST_DIR:-$HOME/.terminal-guru/config-tests}"
ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat << USAGE
Usage: $(basename "$0") [OPTIONS] COMMAND

Systematically test zsh configuration by enabling/disabling components.

COMMANDS:
    levels              Show available test levels
    test LEVEL          Test with specific configuration level
    bisect             Interactive bisection to find problematic config
    snapshot           Create snapshot of current config
    compare S1 S2      Compare two snapshots

TEST LEVELS:
    bare                Minimal zsh (no ZDOTDIR)
    zdotdir-only        ZDOTDIR but no plugins
    plugins-only        ZDOTDIR + plugins, no conf.d
    no-autosuggestions  Everything except autosuggestions
    no-syntax           Everything except syntax highlighting
    full                Full configuration

OPTIONS:
    -n, --name NAME     Test session name
    -t, --tmux          Run in tmux (recommended)
    -h, --help          Show this help

EXAMPLES:
    # Test with minimal config
    $(basename "$0") test bare

    # Bisect to find issue
    $(basename "$0") bisect

    # Compare configurations
    $(basename "$0") snapshot before-fix
    # (make changes)
    $(basename "$0") snapshot after-fix
    $(basename "$0") compare before-fix after-fix

USAGE
    exit 1
}

show_levels() {
    cat << LEVELS
=== Configuration Test Levels ===

Level 0: bare
  - No ZDOTDIR
  - No plugins
  - No custom functions
  - Just basic zsh

Level 1: zdotdir-only
  - ZDOTDIR set
  - .zshenv sourced
  - No plugins loaded
  - No conf.d loaded

Level 2: plugins-only
  - ZDOTDIR set
  - Core plugins loaded (completions, zman, etc.)
  - NO autosuggestions
  - NO syntax highlighting
  - NO conf.d

Level 3: no-autosuggestions
  - Everything except autosuggestions
  - Includes conf.d
  - Includes syntax highlighting

Level 4: no-syntax
  - Everything except syntax highlighting
  - Includes autosuggestions
  - Includes conf.d

Level 5: full
  - Complete configuration
  - All plugins
  - All conf.d files

LEVELS
}

create_test_config() {
    local level="$1"
    local test_name="$2"
    local test_zdotdir="$TEST_DIR/$test_name"
    
    mkdir -p "$test_zdotdir"/{functions,conf.d}
    
    # Create base .zshenv
    cat > "$test_zdotdir/.zshenv" << 'ZSHENV'
# Test ZDOTDIR .zshenv
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

# Minimal path
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
ZSHENV
    
    case "$level" in
        bare)
            # Absolute minimum
            cat > "$test_zdotdir/.zshrc" << 'ZSHRC'
# Bare minimum zsh config
PS1='bare %~ %# '
ZSHRC
            ;;
            
        zdotdir-only)
            # ZDOTDIR but no plugins
            cat > "$test_zdotdir/.zshrc" << 'ZSHRC'
# ZDOTDIR-only config (no plugins)

# Basic prompt
PS1='zdotdir %~ %# '

# Basic history
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000

# Basic completion
autoload -Uz compinit
compinit
ZSHRC
            ;;
            
        plugins-only)
            # Plugins but no conf.d
            create_plugin_config "$test_zdotdir" "minimal"
            ;;
            
        no-autosuggestions)
            # Everything except autosuggestions
            create_plugin_config "$test_zdotdir" "no-autosuggestions"
            # Copy conf.d
            if [[ -d "$ZDOTDIR/conf.d" ]]; then
                cp -r "$ZDOTDIR/conf.d"/* "$test_zdotdir/conf.d/" 2>/dev/null || true
                # Remove autosuggestions config
                rm -f "$test_zdotdir/conf.d"/*autosuggestion* 2>/dev/null || true
            fi
            ;;
            
        no-syntax)
            # Everything except syntax highlighting
            create_plugin_config "$test_zdotdir" "no-syntax"
            # Copy conf.d
            if [[ -d "$ZDOTDIR/conf.d" ]]; then
                cp -r "$ZDOTDIR/conf.d"/* "$test_zdotdir/conf.d/" 2>/dev/null || true
                # Remove syntax config
                rm -f "$test_zdotdir/conf.d"/*syntax* 2>/dev/null || true
            fi
            ;;
            
        full)
            # Copy everything
            if [[ -d "$ZDOTDIR" ]]; then
                cp "$ZDOTDIR/.zshrc" "$test_zdotdir/.zshrc"
                cp "$ZDOTDIR/.zshenv" "$test_zdotdir/.zshenv" 2>/dev/null || true
                cp -r "$ZDOTDIR/conf.d"/* "$test_zdotdir/conf.d/" 2>/dev/null || true
                cp -r "$ZDOTDIR/functions"/* "$test_zdotdir/functions/" 2>/dev/null || true
                # Copy zcomet cache if exists
                if [[ -d "$ZDOTDIR/.zcomet" ]]; then
                    cp -r "$ZDOTDIR/.zcomet" "$test_zdotdir/.zcomet"
                fi
            fi
            ;;
    esac
    
    echo "$test_zdotdir"
}

create_plugin_config() {
    local test_zdotdir="$1"
    local variant="$2"
    
    cat > "$test_zdotdir/.zshrc" << 'ZSHRC_START'
# Test configuration with plugins

# Install zcomet if needed
if [[ ! -f $ZDOTDIR/.zcomet/bin/zcomet.zsh ]]; then
    git clone --quiet https://github.com/agkozak/zcomet.git "$ZDOTDIR/.zcomet/bin" 2>/dev/null || true
fi

# Source zcomet
if [[ -f $ZDOTDIR/.zcomet/bin/zcomet.zsh ]]; then
    source "$ZDOTDIR/.zcomet/bin/zcomet.zsh"
    
    # Core plugins
    zcomet load zsh-users/zsh-completions
    zcomet load mattmc3/zephyr plugins/completion
    zcomet load mattmc3/zephyr plugins/homebrew
    zcomet load mattmc3/zephyr plugins/macos
    zcomet load mattmc3/zephyr plugins/zfunctions
    zcomet load mattmc3/zman
    
    zcomet compinit
    
    zcomet load junegunn/fzf
    zcomet load Aloxaf/fzf-tab
    zcomet load reegnz/jq-zsh-plugin
ZSHRC_START
    
    if [[ "$variant" != "no-autosuggestions" ]]; then
        cat >> "$test_zdotdir/.zshrc" << 'ZSHRC_AUTO'
    
    # Autosuggestions
    zcomet load zsh-users/zsh-autosuggestions
    export ZSH_AUTOSUGGEST_USE_ASYNC=true
    export ZSH_AUTOSUGGEST_MANUAL_REBIND=1
    export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSHRC_AUTO
    fi
    
    if [[ "$variant" != "no-syntax" ]]; then
        cat >> "$test_zdotdir/.zshrc" << 'ZSHRC_SYNTAX'
    
    # Syntax highlighting
    zcomet load zsh-users/zsh-syntax-highlighting
    ZSH_HIGHLIGHT_HIGHLIGHTERS+=(main brackets pattern cursor line)
    ZSH_HIGHLIGHT_MAXLENGTH=512
ZSHRC_SYNTAX
    fi
    
    if [[ "$variant" != "minimal" ]]; then
        cat >> "$test_zdotdir/.zshrc" << 'ZSHRC_CONFD'
    
    # Load conf.d
    zcomet load mattmc3/zephyr plugins/confd
    zcomet load mattmc3/zephyr plugins/color
ZSHRC_CONFD
    fi
    
    cat >> "$test_zdotdir/.zshrc" << 'ZSHRC_END'
fi

# Basic prompt
PS1='test %~ %# '
ZSHRC_END
}

test_level() {
    local level="$1"
    local test_name="${2:-test-$level-$(date +%s)}"
    
    echo -e "${BLUE}Creating test configuration: $level${NC}"
    local test_zdotdir=$(create_test_config "$level" "$test_name")
    
    echo -e "${GREEN}Test ZDOTDIR: $test_zdotdir${NC}"
    echo
    echo -e "${YELLOW}Starting test shell...${NC}"
    echo "Type 'exit' or Ctrl+D when done"
    echo
    
    # Export test ZDOTDIR and start zsh
    env ZDOTDIR="$test_zdotdir" zsh
    
    echo
    echo -e "${GREEN}Test complete${NC}"
    echo "Test files remain in: $test_zdotdir"
}

run_bisect() {
    echo -e "${BLUE}=== Configuration Bisection ===${NC}"
    echo
    echo "This will help you find which part of your config causes issues."
    echo "For each test, type 'exit' and answer if the issue occurred."
    echo
    read -p "Press Enter to start..."
    
    levels=(bare zdotdir-only plugins-only no-autosuggestions no-syntax full)
    
    for level in "${levels[@]}"; do
        echo
        echo -e "${YELLOW}Testing level: $level${NC}"
        echo "Starting test shell..."
        echo
        
        test_level "$level" "bisect-$level"
        
        echo
        read -p "Did the issue occur? (y/n): " answer
        
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            echo -e "${RED}Issue found at level: $level${NC}"
            echo
            echo "The problem is introduced between:"
            local idx=0
            for ((i=0; i<${#levels[@]}; i++)); do
                if [[ "${levels[$i]}" == "$level" ]]; then
                    idx=$i
                    break
                fi
            done
            
            if [[ $idx -gt 0 ]]; then
                echo "  Previous (working): ${levels[$((idx-1))]}"
            fi
            echo "  Current (broken):   $level"
            
            case "$level" in
                zdotdir-only)
                    echo
                    echo "Issue is in ZDOTDIR/.zshenv or ZDOTDIR/.zshrc basics"
                    ;;
                plugins-only)
                    echo
                    echo "Issue is in one of the core plugins"
                    echo "Check: zsh-completions, zephyr, zman, fzf, fzf-tab, jq-zsh-plugin"
                    ;;
                no-autosuggestions)
                    echo
                    echo "Issue is in conf.d files or syntax highlighting"
                    ;;
                no-syntax)
                    echo
                    echo "Issue is in conf.d files or autosuggestions"
                    ;;
                full)
                    echo
                    echo "Issue is in syntax highlighting config"
                    ;;
            esac
            
            break
        else
            echo -e "${GREEN}Level $level: OK${NC}"
        fi
    done
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        levels)
            show_levels
            exit 0
            ;;
        test)
            test_level "$2" "$3"
            exit 0
            ;;
        bisect)
            run_bisect
            exit 0
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown command: $1"
            usage
            ;;
    esac
done

usage
