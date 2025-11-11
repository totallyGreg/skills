#!/bin/bash
# Analyze and document a zsh configuration structure
# This helps understand the loading order and dependencies

ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

echo "=== Zsh Configuration Analysis ==="
echo

# Check main .zshenv
echo "1. Main .zshenv (~/.zshenv):"
if [[ -f ~/.zshenv ]]; then
    echo "   ✓ Exists"
    echo "   ZDOTDIR settings:"
    grep -E "ZDOTDIR|XDG_CONFIG" ~/.zshenv | sed 's/^/     /'
else
    echo "   ✗ Not found"
fi
echo

# Check ZDOTDIR
echo "2. ZDOTDIR ($ZDOTDIR):"
if [[ -d "$ZDOTDIR" ]]; then
    echo "   ✓ Exists"
    echo "   Files:"
    ls -1 "$ZDOTDIR"/.z* 2>/dev/null | sed 's/^/     /'
else
    echo "   ✗ Not found"
fi
echo

# Check plugin manager
echo "3. Plugin Manager:"
if [[ -f "$ZDOTDIR/.zcomet/bin/zcomet.zsh" ]]; then
    echo "   ✓ zcomet detected"
elif [[ -d "$ZDOTDIR/.antigen" ]]; then
    echo "   ✓ antigen detected"
elif [[ -d "$ZDOTDIR/.zinit" ]]; then
    echo "   ✓ zinit detected"
else
    echo "   ✗ No plugin manager detected"
fi
echo

# Check for conf.d
echo "4. Modular Configuration (conf.d):"
if [[ -d "$ZDOTDIR/conf.d" ]]; then
    echo "   ✓ $ZDOTDIR/conf.d exists"
    echo "   Files (load order):"
    ls -1 "$ZDOTDIR/conf.d"/*.zsh 2>/dev/null | sort | sed 's/^/     /'
    echo
    echo "   Loaded via:"
    if grep -q "zephyr plugins/confd" "$ZDOTDIR/.zshrc" 2>/dev/null; then
        echo "     mattmc3/zephyr plugins/confd"
    elif grep -q "conf.d" "$ZDOTDIR/.zshrc" 2>/dev/null; then
        echo "     Manual sourcing detected"
    fi
else
    echo "   ✗ No conf.d directory"
fi
echo

# Check for functions
echo "5. Custom Functions:"
if [[ -d "$ZDOTDIR/functions" ]]; then
    echo "   ✓ $ZDOTDIR/functions exists"
    echo "   Count: $(ls -1 "$ZDOTDIR/functions" 2>/dev/null | wc -l | tr -d ' ') files"
    echo "   Subdirectories:"
    ls -d "$ZDOTDIR/functions"/*/ 2>/dev/null | sed 's/^/     /'
else
    echo "   ✗ No functions directory"
fi
echo

# Check plugins from .zshrc
echo "6. Plugins (from .zshrc):"
if [[ -f "$ZDOTDIR/.zshrc" ]]; then
    echo "   Loaded plugins:"
    grep -E "^[^#]*zcomet load|^[^#]*antigen bundle|^[^#]*zinit" "$ZDOTDIR/.zshrc" 2>/dev/null | \
        sed 's/zcomet load /  • /g' | \
        sed 's/antigen bundle /  • /g' | \
        sed 's/zinit /  • /g' | head -20
else
    echo "   ✗ .zshrc not found"
fi
echo

# Analyze loading order
echo "7. Startup Sequence:"
echo "   ~/.zshenv"
echo "     ↓ Sets ZDOTDIR=$ZDOTDIR"
echo "   $ZDOTDIR/.zshenv (if exists)"
if [[ -f "$ZDOTDIR/.zprofile" ]]; then
    echo "   $ZDOTDIR/.zprofile (login shells)"
fi
echo "   $ZDOTDIR/.zshrc (interactive shells)"
echo "     ↓ Loads plugin manager"
echo "     ↓ Loads plugins via zcomet/antigen/zinit"
echo "     ↓ Loads conf.d/*.zsh (via zephyr/confd)"
echo "     ↓ Sources custom configs"
echo

echo "=== Summary ==="
echo "To test this configuration properly, a test environment needs to:"
echo "1. Respect ZDOTDIR from ~/.zshenv"
echo "2. Clone/copy necessary plugins"
echo "3. Load conf.d files in correct order"
echo "4. Include functions directory in fpath"
echo "5. Handle plugin dependencies"
