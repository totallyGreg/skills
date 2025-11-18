# skill-creator

**Version:** 1.0.0

> Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an existing skill) that extends Claude's capabilities with specialized knowledge, workflows, or tool integrations.

## When to Use This Skill

This skill is triggered when working with tasks related to creating or updating skills.

**Common trigger scenarios:**
- Users want to create a new skill that extends Claude's capabilities
- Users want to update an existing skill with new features
- Users need guidance on skill structure and best practices
- Users want to publish skills to a plugin marketplace

## Skill Structure

- **Main documentation:** SKILL.md
- **Reference guides:**
  - `references/plugin_marketplace_guide.md` (659 lines)
  - `references/advanced-topics.md` (614 lines)

## Bundled Resources

### Scripts

- [`scripts/init_skill.py`](scripts/init_skill.py) - Create new skill from template
- [`scripts/package_skill.py`](scripts/package_skill.py) - Package skill into distributable ZIP
- [`scripts/quick_validate.py`](scripts/quick_validate.py) - Validate skill structure and metadata
- [`scripts/add_to_marketplace.py`](scripts/add_to_marketplace.py) - Manage plugin marketplace creation and updates

### Reference Documentation

- [`references/plugin_marketplace_guide.md`](references/plugin_marketplace_guide.md) - Complete guide to plugin marketplaces
- [`references/advanced-topics.md`](references/advanced-topics.md) - Platform support, security, optimization

## Key Sections

- **About Skills**
  - What Skills Provide
  - Anatomy of a Skill
  - Progressive Disclosure Design Principle
- **Skill Creation Process**
  - Step 1: Understanding the Skill with Concrete Examples
  - Step 2: Planning the Reusable Skill Contents
  - Step 3: Initializing the Skill
  - Step 4: Edit the Skill
  - Step 5: Packaging a Skill
  - Step 6: Add to Plugin Marketplace (Optional)
  - Step 7: Iterate

## Advanced Topics (in references/)

### From advanced-topics.md:
- Platform Support (API, Claude Code, Claude.ai, SDK)
- Marketplace Configuration (critical `skills` array requirement)
- Security Considerations (pre-installation checklist)
- `allowed-tools` Field (restricting tool access)
- Token Budget Optimization (SKILL.md vs references/)
- Naming Convention Guidelines (gerund form rationale)
- Description Quality (anatomy of good descriptions)
- Environment Variables and Piped Commands
- Troubleshooting (skill not triggering, validation errors, conflicts)

### From plugin_marketplace_guide.md:
- When to use marketplaces vs ZIP files
- marketplace.json schema and structure
- Creating marketplaces (step-by-step)
- Organization strategies (3 detailed patterns)
- Version management with semantic versioning
- User installation workflows
- Best practices and troubleshooting

## Usage Examples

### Initialize a new skill

```bash
scripts/init_skill.py my-skill --path ./skills/
```

### Package a skill

```bash
scripts/package_skill.py ./skills/my-skill
```

### Validate a skill

```bash
scripts/quick_validate.py ./skills/my-skill
```

### Create a marketplace

```bash
scripts/add_to_marketplace.py init \
  --name my-marketplace \
  --owner-name "Your Name" \
  --owner-email "email@example.com" \
  --description "Skill collection"
```

### Add skill to marketplace

```bash
scripts/add_to_marketplace.py create-plugin my-plugin \
  "Plugin description" \
  --skills ./my-skill
```

## Features

**Complete skill creation toolkit:**
- Template generation with sensible defaults
- Automated validation with warnings and limits
- One-command packaging for distribution
- Full marketplace management tooling
- Comprehensive documentation for all use cases

**Enhanced validation:**
- Character limit checking (name ≤64, description ≤1024)
- Gerund-form naming convention warnings
- Line count validation (<500 lines recommended)
- YAML frontmatter verification

**Best practices built-in:**
- Progressive disclosure guidance
- Security checklists
- Token budget optimization
- Platform deployment considerations

---

_This skill combines marketplace automation (from totally-tools) with quality validation and best practices (from jshanks)._
