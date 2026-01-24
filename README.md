# Ace Copilot

## Project Overview

The Awesome GitHub Copilot repository is a community-driven collection of custom agents, prompts, and instructions designed to enhance GitHub Copilot experiences across various domains, languages, and use cases. The project includes:

- **Agents** - Specialized GitHub Copilot agents that integrate with MCP servers
- **Prompts** - Task-specific prompts for code generation and problem-solving, you can lauch them, by t
- **Instructions** - Coding standards and best practices applied to specific file patterns
- **Skills** - Self-contained folders with instructions and bundled resources for specialized tasks

## How to Use

### Custom Agents

Custom agents can be used in Copilot coding agent (CCA), VS Code, and Copilot CLI. For CCA, when assigning an issue to Copilot, select the custom agent from the provided list. In VS Code, you can activate the custom agent in the agents session, alongside built-in agents like Plan and Agent.

Find more details in [Custom agents in VS Code](https://code.visualstudio.com/docs/copilot/customization/custom-agents).

### Prompts

Use the `/` command in GitHub Copilot Chat to access prompts:

```plaintext
/awesome-copilot create-readme
```

### Instructions

Instructions automatically apply to files based on their patterns and provide contextual guidance for coding standards, frameworks, and best practices.


## Development Workflow

### Working with Agents, Prompts, Instructions, and Skills

All agent files (`*.agent.md`), prompt files (`*.prompt.md`), and instruction files (`*.instructions.md`) must include proper markdown front matter. Agent Skills are folders containing a `SKILL.md` file with frontmatter and optional bundled assets:

#### Agent Files (*.agent.md)
- Must have `description` field (wrapped in single quotes)
- File names should be lower case with words separated by hyphens
- Recommended to include `tools` field
- Strongly recommended to specify `model` field

#### Prompt Files (*.prompt.md)
- Must have `agent` field (value should be `'agent'` wrapped in single quotes)
- Must have `description` field (wrapped in single quotes, not empty)
- File names should be lower case with words separated by hyphens
- Recommended to specify `tools` if applicable
- Strongly recommended to specify `model` field

#### Instruction Files (*.instructions.md)
- Must have `description` field (wrapped in single quotes, not empty)
- Must have `applyTo` field specifying file patterns (e.g., `'**.js, **.ts'`)
- File names should be lower case with words separated by hyphens

#### Agent Skills (skills/*/SKILL.md)
- Each skill is a folder containing a `SKILL.md` file
- SKILL.md must have `name` field (lowercase with hyphens, matching folder name, max 64 characters)
- SKILL.md must have `description` field (wrapped in single quotes, 10-1024 characters)
- Folder names should be lower case with words separated by hyphens
- Skills can include bundled assets (scripts, templates, data files)
- Bundled assets should be referenced in the SKILL.md instructions
- Asset files should be reasonably sized (under 5MB per file)
- Skills follow the [Agent Skills specification](https://agentskills.io/specification)


### Pre-commit Checklist

Before submitting your PR, ensure you have:
- [ ] Run `bash scripts/fix-line-endings.sh` to normalize line endings
- [ ] Verified that all new files have proper front matter
- [ ] Tested that your contribution works with GitHub Copilot
- [ ] Checked that file names follow the naming convention

### Code Review Checklist

For prompt files (*.prompt.md):
- [ ] Has markdown front matter
- [ ] Has `agent` field (value should be `'agent'` wrapped in single quotes)
- [ ] Has non-empty `description` field wrapped in single quotes
- [ ] File name is lower case with hyphens
- [ ] Includes `model` field (strongly recommended)

For instruction files (*.instructions.md):
- [ ] Has markdown front matter
- [ ] Has non-empty `description` field wrapped in single quotes
- [ ] Has `applyTo` field with file patterns
- [ ] File name is lower case with hyphens

For agent files (*.agent.md):
- [ ] Has markdown front matter
- [ ] Has non-empty `description` field wrapped in single quotes
- [ ] File name is lower case with hyphens
- [ ] Includes `model` field (strongly recommended)
- [ ] Considers using `tools` field

For skills (skills/*/):
- [ ] Folder contains a SKILL.md file
- [ ] SKILL.md has markdown front matter
- [ ] Has `name` field matching folder name (lowercase with hyphens, max 64 characters)
- [ ] Has non-empty `description` field wrapped in single quotes (10-1024 characters)
- [ ] Folder name is lower case with hyphens
- [ ] Any bundled assets are referenced in SKILL.md
- [ ] Bundled assets are under 5MB per file

## License

MIT License - see [LICENSE](LICENSE) for details
