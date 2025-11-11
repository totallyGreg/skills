# Session Capture and Replay Guide

## Quick Start

The terminal-guru skill now includes a powerful session capture and replay system that lets you record terminal sessions, analyze issues, and verify fixes.

### Basic Usage

```bash
cd /Users/totally/.claude/plugins/marketplaces/totally-tools/terminal-guru

# 1. Record a session showing the problem
bash scripts/session_capture.sh -n unicode-problem -d "Emoji backspace issue" start
# (Demonstrate the issue, then exit)

# 2. Analyze the session
python3 scripts/session_validator.py ~/.terminal-guru/sessions/unicode-problem

# 3. Apply fix based on analysis
# (Edit your ~/.zshenv or ~/.zshrc)

# 4. Record session after fix
bash scripts/session_capture.sh -n unicode-fixed -d "After adding LC_ALL" start
# (Demonstrate the fix works, then exit)

# 5. Compare before/after
bash scripts/session_capture.sh compare unicode-problem unicode-fixed

# 6. List all sessions
bash scripts/session_capture.sh list
```

## Use Cases

### 1. Debugging Unicode/Backspace Issues

**Problem**: User reports emoji or CJK characters break backspace

**Solution**:
```bash
# Step 1: Capture the problem in isolated environment
bash scripts/session_capture.sh -t -m \
  -n backspace-before \
  -d "Emoji backspace deletes incorrectly" \
  start

# In the tmux session that opens:
# - Type: 😀🎉✨
# - Try backspacing
# - Exit with Ctrl+D

# Step 2: Validate and identify issues
python3 scripts/session_validator.py ~/.terminal-guru/sessions/backspace-before

# Output might show:
#   ⚠️  LC_ALL not set to UTF-8 locale
#   ❌ Found 1 issue(s) that need attention

# Step 3: Apply fix
echo 'export LC_ALL=en_US.UTF-8' >> ~/.zshenv

# Step 4: Capture after fix
bash scripts/session_capture.sh -t -m \
  -n backspace-after \
  -d "After LC_ALL fix" \
  start

# Test again - should work correctly

# Step 5: Compare
bash scripts/session_capture.sh compare backspace-before backspace-after

# Output shows environment differences:
#   + LC_ALL=en_US.UTF-8
```

### 2. Testing Configuration Changes

**Problem**: Want to test a config change without breaking current setup

**Solution**:
```bash
# Create isolated test session with minimal config
bash scripts/session_capture.sh -t -m -n config-test start

# The session uses minimal config from:
# ~/.terminal-guru/sessions/config-test/.zshrc

# Edit the test config
vim ~/.terminal-guru/sessions/config-test/.zshrc

# Add your experimental configuration
# Test if it works
# If it works, copy to your main ~/.zshrc
```

### 3. Automated Testing

**Problem**: Want to verify terminal is configured correctly

**Solution**:
```bash
# Run all standard tests
bash scripts/session_test.sh all

# Or run specific tests
bash scripts/session_test.sh unicode-emoji
bash scripts/session_test.sh box-drawing
bash scripts/session_test.sh color-256

# Available tests:
# - unicode-basic: Basic Unicode character rendering
# - unicode-emoji: Emoji rendering and backspace
# - unicode-cjk: CJK character display
# - box-drawing: Box drawing characters
# - color-256: 256 color support
# - color-truecolor: 24-bit color
# - backspace-test: Interactive backspace testing
```

### 4. Creating Reproducible Bug Reports

**Problem**: Need to demonstrate a terminal issue to get help

**Solution**:
```bash
# Record the issue
bash scripts/session_capture.sh -n bug-demo -d "Describe the issue" start
# (Demonstrate the problem)

# The session captures everything:
# - Environment variables
# - Locale settings
# - Terminal type
# - Full diagnostic output
# - Actual terminal output

# Share the session directory
tar -czf bug-demo.tar.gz ~/.terminal-guru/sessions/bug-demo

# Someone else can replay it
tar -xzf bug-demo.tar.gz -C ~/
bash scripts/session_capture.sh replay bug-demo
```

## Features in Detail

### Tmux Isolation (`-t` flag)

Runs the session in an isolated tmux environment:

**Benefits**:
- Clean environment
- Separate from your main tmux sessions
- Custom tmux.conf for testing
- Pipe-pane captures all output
- Mouse support enabled
- 10,000 line scrollback

**Example**:
```bash
bash scripts/session_capture.sh -t -n tmux-test start
```

### Minimal Config (`-m` flag)

Uses a stripped-down zsh configuration:

**Minimal config includes**:
- UTF-8 locale settings
- Simple prompt (no fancy themes)
- Basic history
- Basic completion
- No plugins
- No complex prompt

**Perfect for**:
- Isolating configuration issues
- Testing without interference
- Identifying problematic plugins

**Example**:
```bash
bash scripts/session_capture.sh -m -n minimal-test start
```

### Session Validation

Automatically analyzes sessions for common issues:

**Checks**:
- ✅ Locale is UTF-8
- ✅ Environment variables set correctly
- ✅ TERM is appropriate (256color)
- ✅ No UTF-8 encoding errors
- ✅ Unicode characters rendered correctly
- ⚠️ Warnings for potential issues
- ❌ Errors for critical problems

**Example**:
```bash
python3 scripts/session_validator.py ~/.terminal-guru/sessions/my-session

# Output:
# ============================================================
#   Validating session: my-session
# ============================================================
# 
# 📋 Information:
#    ℹ️  Session: my-session
#    ℹ️  Description: Testing emoji
#    ℹ️  Created: 2025-11-10T19:30:00Z
#    ℹ️  Found 15 emoji sequences
# 
# ⚠️  Warnings:
#    ⚠️  LC_ALL not set to UTF-8 locale
# 
# ❌ Found 0 issue(s) that need attention
# ⚠️  Found 1 warning(s)
```

### Session Comparison

Compare two sessions to see exactly what changed:

**Compares**:
- Environment variables
- Locale settings
- Diagnostics output
- Metadata

**Example**:
```bash
bash scripts/session_capture.sh compare before after

# Shows diff output:
# === Environment Differences ===
# - LC_ALL=
# + LC_ALL=en_US.UTF-8
# 
# === Locale Differences ===
# (shows locale changes)
```

## Directory Structure

Sessions are stored in `~/.terminal-guru/sessions/`:

```
~/.terminal-guru/
├── sessions/
│   ├── unicode-problem/
│   │   ├── metadata.json          # Session info
│   │   ├── environment.txt        # env output
│   │   ├── locale.txt            # locale output
│   │   ├── diagnostics.txt       # Full diagnostics
│   │   ├── typescript            # Recorded output
│   │   ├── timing.txt           # Timing for replay
│   │   ├── tmux.conf            # If -t used
│   │   ├── .zshenv              # If -m used
│   │   ├── .zshrc               # If -m used
│   │   └── run.sh               # Launch script
│   └── unicode-fixed/
│       └── ...
└── tests/
    ├── results/                   # Test results
    └── custom-test.sh            # Custom tests
```

## Advanced Usage

### Custom Test Scenarios

Create your own test scenarios:

```bash
# Create custom test
cat > ~/.terminal-guru/tests/my-test.sh << 'TESTEOF'
#!/bin/bash
echo "=== My Custom Test ==="
echo "Testing specific characters: 你好 😀 ┌─┐"
# Add your specific test commands
TESTEOF

chmod +x ~/.terminal-guru/tests/my-test.sh

# Run custom test
bash scripts/session_test.sh my-test
```

### Replaying with Timing

If `scriptreplay` is available, sessions replay with original timing:

```bash
# Replay with timing (shows typing as it happened)
bash scripts/session_capture.sh replay my-session

# Just view output without timing
cat ~/.terminal-guru/sessions/my-session/typescript
```

### Remote Session Capture

Capture sessions on remote systems:

```bash
# Copy scripts to remote
scp -r scripts/ user@remote:~/terminal-guru-scripts/

# SSH and capture
ssh user@remote
cd ~/terminal-guru-scripts
bash session_capture.sh -n remote-issue start

# Copy back for analysis
exit
scp -r user@remote:~/.terminal-guru/sessions/remote-issue \
    ~/.terminal-guru/sessions/
```

## Troubleshooting

### "scriptreplay: command not found"

**Solution**: Install bsdutils or util-linux, or just view the typescript:
```bash
cat ~/.terminal-guru/sessions/session-name/typescript
```

### "jq: command not found"

**Solution**: Install jq or view JSON manually:
```bash
# macOS
brew install jq

# Or view manually
cat ~/.terminal-guru/sessions/session-name/metadata.json
```

### Tmux session not isolated

**Problem**: Tmux using your main config

**Solution**: Ensure you use both `-t` and `-m` flags:
```bash
bash scripts/session_capture.sh -t -m start
```

### Session not capturing output

**Problem**: Empty typescript file

**Solution**: Make sure to actually run commands in the session before exiting. The session starts recording immediately.

## Examples

### Complete Workflow: Fix Unicode Backspace Issue

```bash
# 1. Initial diagnostics
python3 scripts/terminal_diagnostics.py > ~/initial-diagnostics.txt

# 2. Capture problem
bash scripts/session_capture.sh -t -m -n emoji-broken \
  -d "Emoji require 2 backspaces instead of 1" start

# In the session:
# Type: 😀🎉
# Try backspacing (observe problem)
# Exit

# 3. Validate
python3 scripts/session_validator.py ~/.terminal-guru/sessions/emoji-broken

# Output shows:
#   ⚠️  LC_ALL not set to UTF-8 locale

# 4. Apply fix
echo 'export LC_ALL=en_US.UTF-8' >> ~/.zshenv

# 5. Test fix
bash scripts/session_capture.sh -t -m -n emoji-fixed \
  -d "After adding LC_ALL=en_US.UTF-8" start

# In the session:
# Type: 😀🎉
# Try backspacing (should work correctly)
# Exit

# 6. Compare
bash scripts/session_capture.sh compare emoji-broken emoji-fixed

# 7. Validate fix
python3 scripts/session_validator.py ~/.terminal-guru/sessions/emoji-fixed

# Output shows:
#   ✅ No critical issues found!

# 8. Run full test suite to verify no regressions
bash scripts/session_test.sh all

# 9. Clean up test sessions
bash scripts/session_capture.sh clean emoji-broken
bash scripts/session_capture.sh clean emoji-fixed
```

## Integration with terminal-guru Skill

When using the terminal-guru skill with Claude, the agent can:

1. **Diagnose issues**: Run diagnostics and identify problems
2. **Capture sessions**: Record your terminal showing the issue
3. **Validate sessions**: Automatically analyze for common problems
4. **Apply fixes**: Make configuration changes
5. **Verify fixes**: Capture new session and compare
6. **Run tests**: Execute test suite to ensure everything works

The session capture system makes it easy to:
- Show exactly what's wrong
- Test fixes in isolation
- Prove fixes work
- Avoid breaking existing configuration

## Best Practices

1. **Name sessions descriptively**: Use `-n` with clear names like "emoji-before-fix"
2. **Add descriptions**: Use `-d` to document what you're testing
3. **Use isolation**: Combine `-t` and `-m` for clean testing
4. **Validate everything**: Always run validator on captured sessions
5. **Compare before/after**: Use compare to see exact changes
6. **Clean up**: Remove old sessions with `clean` command
7. **Document findings**: Session metadata tracks what you discover

## Next Steps

Now that you understand the session capture system, you can:

1. **Record your current issue**: Capture a session showing the problem
2. **Analyze automatically**: Let the validator identify issues
3. **Test fixes safely**: Use isolated sessions to test changes
4. **Verify results**: Compare before/after sessions
5. **Document solutions**: Share session directories as reproducible examples

The session capture system makes terminal debugging systematic, reproducible, and safe!
