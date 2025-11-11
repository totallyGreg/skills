# Zsh Configuration Testing Guide

## Overview

The terminal-guru skill now includes sophisticated tools for testing zsh configurations that properly respect:
- `ZDOTDIR` from `~/.zshenv`
- Plugin managers (zcomet, antigen, zinit)
- Modular configuration via `conf.d/`
- Custom functions directories
- Plugin load order and dependencies

## Tools

### 1. Configuration Analyzer (`zsh_config_analyzer.sh`)

Analyzes your current zsh setup and documents the structure.

**Usage**:
```bash
bash scripts/zsh_config_analyzer.sh
```

**Output**:
- Main `~/.zshenv` settings
- ZDOTDIR location and files
- Plugin manager detection
- conf.d files and load order
- Custom functions
- Loaded plugins
- Startup sequence diagram

**When to use**: Before testing, to understand your configuration structure.

### 2. Configuration Bisection Tool (`zsh_config_bisect.sh`)

Systematically test your config by enabling/disabling components to find issues.

**Usage**:
```bash
# Show available test levels
bash scripts/zsh_config_bisect.sh levels

# Test specific level
bash scripts/zsh_config_bisect.sh test bare
bash scripts/zsh_config_bisect.sh test plugins-only
bash scripts/zsh_config_bisect.sh test full

# Interactive bisection
bash scripts/zsh_config_bisect.sh bisect
```

**Test Levels**:

| Level | Description | Use Case |
|-------|-------------|----------|
| `bare` | Minimal zsh, no ZDOTDIR | Test if issue is zsh itself |
| `zdotdir-only` | ZDOTDIR but no plugins | Test basic config without plugins |
| `plugins-only` | Core plugins, no conf.d | Test plugin manager and core plugins |
| `no-autosuggestions` | Everything except autosuggestions | Test if autosuggestions cause issue |
| `no-syntax` | Everything except syntax highlighting | Test if syntax highlighting causes issue |
| `full` | Complete configuration | Test full config |

**When to use**: When you have an issue and need to find which component causes it.

## Methodical Testing Workflow

### Understanding Your Configuration Flow

Your zsh configuration follows this sequence:

```
1. ~/.zshenv
   ├─ Sets XDG_CONFIG_HOME
   ├─ Sets ZDOTDIR=$XDG_CONFIG_HOME/zsh
   └─ Sets up PATH

2. $ZDOTDIR/.zshenv (if exists)
   └─ Additional environment variables

3. $ZDOTDIR/.zshrc (interactive shells)
   ├─ Loads zcomet (plugin manager)
   ├─ Loads plugins via zcomet load
   │  ├─ zsh-completions
   │  ├─ zephyr (completion, homebrew, macos, zfunctions)
   │  ├─ zman
   │  ├─ fzf + fzf-tab
   │  ├─ jq-zsh-plugin
   │  ├─ autosuggestions
   │  └─ syntax-highlighting
   ├─ Loads conf.d/*.zsh (via zephyr/confd plugin)
   │  ├─ ~dev-environments.zsh
   │  ├─ ~fzf-tab-completion.zsh
   │  ├─ 90-keybinds.zsh
   │  ├─ 92-fzf.zsh
   │  ├─ 93-fzf-tab.zsh
   │  ├─ 95-autosuggestions.zsh
   │  ├─ completions.zsh
   │  ├─ history.zsh
   │  └─ ... (loaded alphabetically)
   └─ Custom configurations

4. Functions are autoloaded from:
   ├─ $ZDOTDIR/functions/
   ├─ $ZDOTDIR/functions/kubernetes/
   └─ $ZDOTDIR/functions/fabric/
```

### Workflow 1: Find Which Component Causes Issue

**Problem**: Terminal has an issue but you don't know which config causes it.

**Solution**: Use bisection

```bash
# Run interactive bisection
bash scripts/zsh_config_bisect.sh bisect

# You'll be prompted to test each level
# Answer y/n if issue occurs
# Tool will identify the problematic component
```

**Example**:
```
Testing level: bare
Did the issue occur? (y/n): n

Testing level: zdotdir-only  
Did the issue occur? (y/n): n

Testing level: plugins-only
Did the issue occur? (y/n): n

Testing level: no-autosuggestions
Did the issue occur? (y/n): n

Testing level: no-syntax
Did the issue occur? (y/n): y

Issue found at level: no-syntax
The problem is introduced between:
  Previous (working): no-autosuggestions
  Current (broken):   no-syntax

Issue is in conf.d files or autosuggestions
```

### Workflow 2: Test Specific Component

**Problem**: You suspect autosuggestions cause emoji width issues.

**Solution**: Test without that component

```bash
# Test without autosuggestions
bash scripts/zsh_config_bisect.sh test no-autosuggestions

# In the test shell:
cd ~/.config/zsh/debug_dir/
ls    # Type and watch for issues
# Test your specific scenario
exit

# If issue doesn't occur, autosuggestions is the problem
```

### Workflow 3: Test Configuration Change

**Problem**: Want to test a fix without breaking main config.

**Solution**: Use session capture with different levels

```bash
# First, capture the problem
cd /path/to/terminal-guru

# Test with current config (problem exists)
bash scripts/session_capture.sh -t -n before-fix -d "Emoji issue before fix" start
# Demonstrate the issue
# Exit

# Make your fix in a test level
# Create custom test by modifying a level
bash scripts/zsh_config_bisect.sh test no-autosuggestions

# In the test shell, verify your fix idea works
# If it works, you know what to fix in main config
```

### Workflow 4: Debug conf.d File

**Problem**: Issue is in conf.d but you don't know which file.

**Solution**: Manually test conf.d files

```bash
# Test without conf.d
bash scripts/zsh_config_bisect.sh test plugins-only

# In test shell - manually source conf.d files one by one
source $REAL_ZDOTDIR/conf.d/90-keybinds.zsh
# Test - OK?
source $REAL_ZDOTDIR/conf.d/92-fzf.zsh
# Test - OK?
source $REAL_ZDOTDIR/conf.d/95-autosuggestions.zsh
# Test - ISSUE!
# Found it: 95-autosuggestions.zsh
```

### Workflow 5: Capture Session at Each Level

**Problem**: Want to compare diagnostics at different config levels.

**Solution**: Capture sessions at each level

```bash
levels=(bare zdotdir-only plugins-only no-autosuggestions full)

for level in "${levels[@]}"; do
    # Start test at level
    bash scripts/zsh_config_bisect.sh test "$level"
    
    # In test shell:
    # cd to problem directory
    # try to reproduce issue
    # exit
    
    # Capture what happened
    python3 scripts/terminal_diagnostics.py > "diag-$level.txt"
done

# Compare diagnostics
diff diag-bare.txt diag-full.txt
```

## Real-World Example: Emoji Prompt Issue

Your emoji prompt issue can be debugged systematically:

```bash
# Step 1: Analyze your config
bash scripts/zsh_config_analyzer.sh > my-config-analysis.txt

# Step 2: Run bisection
bash scripts/zsh_config_bisect.sh bisect

# At each level, test:
cd ~/.config/zsh/debug_dir/
ls    # Start typing, watch for autosuggestions with emoji
# Note if cursor/prompt corruption occurs

# Step 3: Based on bisection results, test specific component
# If issue is at "no-syntax" level, it's either:
# - conf.d files
# - autosuggestions config

# Test just autosuggestions config
bash scripts/zsh_config_bisect.sh test plugins-only

# In test shell, manually add autosuggestions settings:
export ZSH_AUTOSUGGEST_USE_ASYNC=true
export ZSH_AUTOSUGGEST_MANUAL_REBIND=1
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# Test again
cd ~/.config/zsh/debug_dir/
ls    # Type and watch
# If fixed, these settings are the solution
```

## Best Practices

### 1. Always Start with Analysis

```bash
# Before any testing:
bash scripts/zsh_config_analyzer.sh
```

This shows you exactly what your config loads and in what order.

### 2. Test from Minimal to Full

Don't start with `full` - start with `bare` and work up:
- `bare` - eliminates zsh itself as problem
- `zdotdir-only` - tests basic config
- `plugins-only` - tests plugin system
- `no-autosuggestions` - tests without one plugin
- `full` - complete config

### 3. Document Your Findings

Create notes for each test:
```bash
# Create test log
echo "Test: no-autosuggestions" > test-log.txt
echo "Date: $(date)" >> test-log.txt
bash scripts/zsh_config_bisect.sh test no-autosuggestions
# After testing:
echo "Result: Issue did not occur" >> test-log.txt
echo "Conclusion: Autosuggestions causes the issue" >> test-log.txt
```

### 4. Test in Isolation

Use tmux for isolated testing:
```bash
# Start isolated tmux session for testing
tmux new-session -s test-config

# In tmux, run your tests
bash scripts/zsh_config_bisect.sh test plugins-only

# Can kill tmux session without affecting main shell
tmux kill-session -t test-config
```

### 5. Preserve Working Configs

When you find a working configuration:
```bash
# Copy the working test config
cp -r ~/.terminal-guru/config-tests/test-plugins-only ~/.terminal-guru/configs/working-base

# Document what works
echo "Plugins-only config works without emoji issue" > ~/.terminal-guru/configs/working-base/README.txt
```

## Configuration Testing Checklist

When debugging an issue:

- [ ] Run config analyzer to understand structure
- [ ] Run bisection to find problematic level
- [ ] Test specific component in isolation
- [ ] Check conf.d files if issue in that layer
- [ ] Test with minimal ZDOTDIR
- [ ] Verify fix in isolation before applying to main config
- [ ] Document which component caused issue
- [ ] Document the fix applied

## Advanced: Custom Test Levels

You can create custom test configs by modifying the bisection tool's output:

```bash
# Generate a test config
bash scripts/zsh_config_bisect.sh test plugins-only

# The config is created in:
# ~/.terminal-guru/config-tests/test-plugins-only/

# Customize it
vim ~/.terminal-guru/config-tests/test-plugins-only/.zshrc

# Test your custom config
ZDOTDIR=~/.terminal-guru/config-tests/test-plugins-only zsh
```

## Integration with Session Capture

The bisection tool integrates with session capture:

```bash
# Capture session at specific config level
# (Future enhancement - session_capture_v2.sh will support this)

# For now, manually:
bash scripts/zsh_config_bisect.sh test no-autosuggestions

# In test shell:
script -q ~/session-no-autosuggest.txt
# Reproduce issue
# Exit

# Analyze the session
cat ~/session-no-autosuggest.txt
```

## Troubleshooting the Testing Tools

### "zcomet not found"

The bisection tool will auto-install zcomet if needed. If it fails:
```bash
# Manually clone zcomet
git clone https://github.com/agkozak/zcomet.git ~/.terminal-guru/config-tests/test-name/.zcomet/bin
```

### "Plugins not loading"

Test configs create fresh plugin installations. First run may be slow while plugins download.

### "conf.d files not found"

Ensure your real config has conf.d:
```bash
ls -la $ZDOTDIR/conf.d/
```

The bisection tool copies from your real ZDOTDIR.

## Summary

The new testing system provides:

1. **Analysis**: Understand your config structure
2. **Bisection**: Find which component causes issues
3. **Isolation**: Test components individually  
4. **Methodology**: Systematic approach to debugging
5. **ZDOTDIR-aware**: Respects real zsh configuration flow
6. **Plugin-aware**: Handles zcomet/antigen/zinit
7. **conf.d support**: Tests modular configurations
8. **Function support**: Includes custom functions

This makes terminal debugging methodical, reproducible, and safe!
