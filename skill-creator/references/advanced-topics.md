# Advanced Skill Creation Topics

This reference provides detailed information for advanced skill creation topics. Load this file when you need specific guidance on platform support, security, optimization, or troubleshooting.

## Platform Support

Skills can be deployed across multiple Claude platforms, but **do not auto-sync** between them:

### Claude API
- Deploy via `skills` parameter in API requests
- Programmatic integration with your applications
- Skills sent with each API call

### Claude Code
- **Personal skills**: `~/.claude/skills/` - Available across all projects
- **Project skills**: `.claude/skills/` - Specific to one project
- **Plugin skills**: Installed via plugin system
- Auto-loaded based on context and user requests

### Claude.ai
- Upload skills via web interface
- Available in web conversations
- Stored in cloud for that account

### Agent SDK
- Programmatic skill integration
- Full control over skill loading and execution

**Important**: Installing a skill in one platform does not make it available in others. To use a skill across platforms, install separately in each.

## Marketplace Configuration

When distributing skills via a marketplace (plugin system), the marketplace must be properly configured with a `marketplace.json` file.

### Required Structure

The `marketplace.json` file must be located at `.claude-plugin/marketplace.json` relative to the marketplace root directory.

### Marketplace Manifest Format

```json
{
  "name": "marketplace-name",
  "owner": {
    "name": "Owner Name",
    "email": "owner@example.com"
  },
  "plugins": [
    {
      "name": "plugin-name",
      "source": "./path/to/plugin",
      "skills": ["./path/to/skill"]
    }
  ]
}
```

### Critical: The skills Array

**The `skills` array is required for Claude Code to load skills from a plugin.** Without it, the plugin will be registered but no skills will be exposed.

**Single-skill plugin:**
```json
{
  "name": "my-skill",
  "source": "./skills/my-skill",
  "skills": ["./"]
}
```

**Multi-skill plugin:**
```json
{
  "name": "my-plugin-bundle",
  "source": "./",
  "skills": [
    "./skill-one",
    "./skill-two",
    "./skill-three"
  ]
}
```

### Field Definitions

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Plugin name (used for installation: `plugin install name@marketplace`) |
| `source` | string | Path to plugin's root directory (relative to marketplace root) |
| `skills` | array | Paths to skill directories containing SKILL.md files (relative to `source`) |

### Path Resolution

Paths in the `skills` array are resolved relative to the `source` directory. The schema requires all paths to start with `"./"`.

For single-skill plugins where SKILL.md is at the root of the source directory:

```json
{
  "name": "my-skill",
  "source": "./skills/my-skill",
  "skills": ["./"]
}
```

This resolves to: `marketplace-root/skills/my-skill/SKILL.md`

For multi-skill plugins with nested structure:

```json
{
  "name": "example",
  "source": "./",
  "skills": ["./skills/example"]
}
```

This resolves to: `marketplace-root/skills/example/SKILL.md`

### Verification Checklist

When configuring a marketplace:
- [ ] `marketplace.json` exists at `.claude-plugin/marketplace.json`
- [ ] Each plugin entry includes a `skills` array
- [ ] Each path in `skills` array points to a directory with `SKILL.md`
- [ ] `SKILL.md` has proper frontmatter (name, description, version)
- [ ] Paths are relative to the marketplace root or source as appropriate
- [ ] After installation, restart Claude Code to load skills

### Common Issues

**Skill not appearing after installation:**
- Most common cause: Missing `skills` array in plugin entry
- Solution: Add `"skills": ["./"]` to the plugin entry (for single-skill plugins)
- Verification: Check `~/.claude/plugins/marketplaces/<name>/.claude-plugin/marketplace.json`
- Note: All paths in the `skills` array must start with `"./"`

**Incorrect path resolution:**
- Symptom: Plugin installs but skill not found
- Check: Verify SKILL.md exists at the resolved path
- Solution: Adjust `skills` array paths to correctly reference SKILL.md locations

### Example Marketplace Structure

Complete example showing proper organization:

```
my-marketplace/
├── .claude-plugin/
│   └── marketplace.json          # Marketplace manifest
├── skills/
│   ├── skill-one/
│   │   └── SKILL.md
│   ├── skill-two/
│   │   └── SKILL.md
│   └── skill-three/
│       └── SKILL.md
```

Corresponding `marketplace.json`:

```json
{
  "name": "my-marketplace",
  "owner": {
    "name": "Developer Name",
    "email": "dev@example.com"
  },
  "plugins": [
    {
      "name": "skill-one",
      "source": "./skills/skill-one",
      "skills": ["./"]
    },
    {
      "name": "skill-two",
      "source": "./skills/skill-two",
      "skills": ["./"]
    },
    {
      "name": "skill-three",
      "source": "./skills/skill-three",
      "skills": ["./"]
    }
  ]
}
```

## Security Considerations

Before using external or third-party skills, complete this security checklist:

### Pre-Installation Security Checklist
- [ ] **Source is trusted**: Verify the skill comes from a known, reputable source
- [ ] **SKILL.md audited**: Review instructions for malicious or dangerous commands
- [ ] **Scripts reviewed**: Check all scripts in `scripts/` for security vulnerabilities
  - Look for command injection risks
  - Check file system operations
  - Verify network requests are legitimate
  - Ensure no credential harvesting
- [ ] **File permissions**: Verify permissions are appropriate (no unnecessary execute bits)
- [ ] **No credential exposure**: Ensure no API keys, tokens, or passwords in files
- [ ] **References reviewed**: Check reference files for embedded malicious content

### Security Best Practices
- Only install skills from sources you trust
- Review all code before execution
- Use `allowed-tools` to restrict tool access when appropriate
- Keep skills updated from trusted sources
- Remove unused skills to reduce attack surface

## allowed-tools Field

The optional `allowed-tools` field in YAML frontmatter restricts which tools Claude can use when executing a skill.

### Purpose
- **Security**: Prevent skills from accessing sensitive tools
- **Focus**: Keep skills constrained to their intended domain
- **Safety**: Prevent unintended side effects

### Format
```yaml
---
name: example-skill
description: Example skill with restricted tools
allowed-tools:
  - Read
  - Write
  - Bash
---
```

### Use Cases

**Read-only analysis skills:**
```yaml
allowed-tools:
  - Read
  - Grep
  - Glob
```

**Documentation skills:**
```yaml
allowed-tools:
  - Read
  - Write
```

**Data processing skills:**
```yaml
allowed-tools:
  - Read
  - Write
  - Bash
```

### When to Use
- Skills that should never modify files (analysis, reporting)
- Skills with security sensitivity (handling credentials, sensitive data)
- Skills focused on specific domains (documentation only, testing only)

### When Not to Use
- General-purpose skills that need flexibility
- Skills that require diverse tool access
- Skills where tool needs vary significantly by use case

## Token Budget Optimization

Managing token budgets effectively is crucial for skill performance and cost.

### SKILL.md Budget Guidelines
- **Target**: <5k tokens, <500 lines
- **Hard limit**: Keep under 10k tokens
- **Why**: SKILL.md loads every time the skill triggers

### When to Split Content into references/

Move these to `references/` files:
- **Detailed schemas** (>200 lines): Database schemas, API response formats
- **API documentation**: Endpoint references, authentication details
- **Extensive examples**: Multiple detailed code examples
- **Platform-specific details**: Deployment guides, configuration options
- **Troubleshooting guides**: Long debugging workflows
- **Historical context**: Background that's useful but not essential

### Keeping SKILL.md Lean

Keep these in SKILL.md:
- **Core workflow**: Essential step-by-step process
- **Critical requirements**: Must-know constraints and rules
- **Quick reference**: Tables, checklists for common tasks
- **Cross-references**: Pointers to relevant `references/` files
- **Illustrative examples**: One or two concrete examples only

### Progressive Disclosure Strategy

Structure content in layers:
1. **SKILL.md**: "What to do" - essential workflow only
2. **references/**: "How in detail" - comprehensive guides
3. **Claude loads references/**: Only when needed during execution

### Optimization Techniques

**Use tables instead of prose:**
```markdown
# Instead of:
The name field should be lowercase with hyphens and no more than 64 characters...

# Use:
| Field | Format | Max Length |
|-------|--------|------------|
| name  | lowercase-with-hyphens | 64 chars |
```

**Reference instead of repeat:**
```markdown
# Instead of copying documentation:
For detailed API documentation, see references/api-docs.md

# Claude will load it when needed
```

**Link to scripts:**
```markdown
# Instead of inline code:
Use scripts/process_data.py to transform the data

# Keeps SKILL.md clean, script executable without loading
```

## Naming Convention Guidelines

### Gerund Form Rationale

Use gerund form (verb-ing) to describe **ongoing capability** rather than completed state:

**Good examples:**
- `processing-pdfs` - Conveys ongoing PDF processing capability
- `creating-diagrams` - Describes continuous diagram creation
- `analyzing-code` - Indicates code analysis capability
- `managing-databases` - Shows database management function

**Bad examples:**
- `pdf-processor` - Sounds like a tool, not a capability
- `diagram-creator` - Tool-focused, not process-focused
- `code-analyzer` - Less clear about ongoing nature
- `database-manager` - Ambiguous (person vs. capability)

### Other Naming Rules

**Always lowercase with hyphens:**
- ✅ `skill-creator`
- ✅ `test-driven-development`
- ❌ `SkillCreator`
- ❌ `skill_creator`

**Keep concise (≤64 characters):**
- ✅ `generating-api-documentation`
- ❌ `generating-comprehensive-api-documentation-with-examples-and-guides`

**Be specific:**
- ✅ `rotating-pdf-pages`
- ❌ `pdf-tool`

## Description Quality

The description field is **critical** - it determines when Claude uses your skill.

### Anatomy of a Good Description

A quality description has three components:

1. **What the skill does** (specific functionality)
2. **When to use it** (trigger conditions)
3. **Context clues** (keywords Claude should recognize)

### Good Examples

```yaml
description: Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an existing skill) that extends Claude's capabilities with specialized knowledge, workflows, or tool integrations.
```
- ✅ Specific: "creating effective skills"
- ✅ Trigger: "when users want to create a new skill"
- ✅ Context: "update an existing skill", "specialized knowledge"

```yaml
description: Use when processing PDF files to extract text, rotate pages, or merge documents. Triggers on PDF-related requests like "rotate this PDF" or "extract text from this document."
```
- ✅ Specific: Lists exact capabilities
- ✅ Trigger: "PDF-related requests"
- ✅ Examples: Shows trigger phrases

```yaml
description: Comprehensive spreadsheet creation, editing, and analysis with support for formulas, formatting, data analysis, and visualization. When Claude needs to work with spreadsheets (.xlsx, .xlsm, .csv, .tsv, etc) for creating, reading, modifying, or analyzing data.
```
- ✅ Specific: Details spreadsheet capabilities
- ✅ Trigger: File types listed
- ✅ Context: Multiple use cases enumerated

### Bad Examples

```yaml
description: PDF skill
```
- ❌ Too vague
- ❌ No trigger information
- ❌ No context clues

```yaml
description: Does everything with PDFs including all operations you might need for working with PDF documents in any context.
```
- ❌ Not specific about capabilities
- ❌ No concrete triggers
- ❌ Wordy but uninformative

```yaml
description: Rotate PDFs.
```
- ❌ Too narrow (might do more)
- ❌ No trigger information
- ❌ Missing context (what about "rotate this document"?)

### Description Quality Checklist

When writing descriptions, verify:
- [ ] **Specific functionality**: Lists what the skill actually does
- [ ] **Clear triggers**: Describes when/how skill should activate
- [ ] **Relevant keywords**: Includes terms users might say
- [ ] **Third-person format**: "This skill should be used when..." not "Use this when..."
- [ ] **Within 1024 chars**: Respects character limit
- [ ] **No redundancy**: Every word adds value
- [ ] **Accurate scope**: Neither too broad nor too narrow

## Environment Variables and Piped Commands

When creating skills that use environment variables in bash commands with pipes, be aware of a critical shell expansion issue.

### The Problem

When piping commands that use environment variables (like `$API_TOKEN`) to tools like `jq`, `grep`, or other commands, the environment variable expands to an empty string, causing authentication failures or missing data.

**Example of the issue:**
```bash
# ❌ WRONG - $API_TOKEN expands to empty string
curl "https://api.example.com/endpoint" \
  -H "Authorization: Bearer $API_TOKEN" | jq '.data'
# Result: Authentication failure
```

This occurs because of how the Bash tool executes commands using `eval` with double quotes. When a pipe is present, the variable expansion happens at the wrong time in the execution context.

### The Solution

Wrap commands that use environment variables in `bash -c` with single quotes before the pipe:

```bash
# ✅ CORRECT - Use bash -c wrapper
bash -c 'curl "https://api.example.com/endpoint" \
  -H "Authorization: Bearer $API_TOKEN"' | jq '.data'
```

### Decision Tree for Skills

When documenting bash commands in your skill:

```
Does the command use environment variables?
├─ No → Use normally: command args | pipe
└─ Yes → Does it have a pipe?
    ├─ No → Use variable directly: curl ... -H "Auth: $TOKEN"
    └─ Yes → Use bash -c wrapper: bash -c 'curl ... -H "Auth: $TOKEN"' | jq
```

### Key Patterns to Document

**Command substitution (works without wrapper):**
```bash
# Variable assignment - no wrapper needed
response=$(curl ... -H "Authorization: Bearer $TOKEN")
echo "$response" | jq '.data'
```

**Direct piping with environment variables (needs wrapper):**
```bash
# Must use bash -c wrapper
bash -c 'curl ... -H "Authorization: Bearer $TOKEN"' | jq '.data'
```

**Multi-stage pipelines:**
```bash
# Only wrap the first command that uses environment variables
bash -c 'curl ... -H "Authorization: Bearer $TOKEN"' \
  | jq '.data[]' \
  | grep "pattern" \
  | sort
```

### When to Include This in Your Skill

Include this guidance if your skill:
- Uses API authentication with environment variables
- Involves bash commands that commonly pipe to `jq`, `grep`, `head`, etc.
- Provides example commands for users to run
- Works with any environment-variable-based configuration

### Example Documentation Pattern

In your SKILL.md or references/, include:

```markdown
## Using API Commands with Pipes

When piping API requests to tools like jq, wrap the command in bash -c:

\`\`\`bash
# Pattern
bash -c 'curl "https://api.example.com/endpoint" \\
  -H "Authorization: Bearer $API_TOKEN"' | jq '.data'
\`\`\`

This prevents environment variable expansion issues in piped commands.
```

### Testing Your Skill Examples

Before finalizing your skill, verify that:
- [ ] All bash examples with environment variables and pipes use `bash -c` wrapper
- [ ] Examples without pipes use environment variables directly (no wrapper needed)
- [ ] Variable assignment with `$(...)` is documented as not needing the wrapper
- [ ] Multi-stage pipelines only wrap the command with environment variables

## Troubleshooting

### Skill Not Triggering

**Symptom**: Skill exists but Claude doesn't use it when expected.

**Diagnosis**:
1. Check description specificity - Is it clear when to use?
2. Review trigger keywords - Do they match user requests?
3. Verify no competing skills with overlapping descriptions
4. Check skill installation location (correct directory)

**Solutions**:
- Add more specific trigger phrases to description
- Include file extensions or domain keywords
- Make description more concrete about use cases
- Test with exact phrases you expect users to say

### Validation Errors During Packaging

**Symptom**: `package_skill.py` fails with validation errors.

**Common Issues**:
- **Name too long**: Reduce to ≤64 characters
- **Description too long**: Trim to ≤1024 characters
- **Invalid YAML**: Check frontmatter syntax, indentation
- **Missing required fields**: Ensure `name` and `description` present
- **Bad naming format**: Use lowercase-with-hyphens only

**Solutions**:
- Review YAML frontmatter carefully
- Check character counts
- Validate YAML syntax with a linter
- Follow naming conventions exactly

### Skill Conflicts

**Symptom**: Wrong skill triggers, or multiple skills activate.

**Diagnosis**:
1. Compare descriptions of similar skills
2. Check for overlapping keywords
3. Review trigger conditions

**Solutions**:
- Make descriptions more specific and differentiated
- Use `allowed-tools` to narrow skill scope
- Consolidate overlapping skills
- Add negative triggers ("not for X, use Y skill instead")

### Performance Issues

**Symptom**: Skill loads slowly or uses too many tokens.

**Diagnosis**:
1. Check SKILL.md line count and token count
2. Review if detailed content could move to references/
3. Check for repeated information

**Solutions**:
- Move detailed schemas to `references/`
- Use tables instead of prose
- Link to scripts instead of inline code
- Remove redundant examples
- Split large skills into focused sub-skills

### Scripts Not Executing

**Symptom**: Scripts in `scripts/` directory don't run.

**Diagnosis**:
1. Check file permissions (should be executable)
2. Verify shebang line in script
3. Check Python/Bash version compatibility
4. Review SKILL.md for correct script references

**Solutions**:
- Add execute permissions: `chmod +x scripts/script.py`
- Ensure proper shebang: `#!/usr/bin/env python3`
- Test scripts independently
- Update SKILL.md with correct script paths
