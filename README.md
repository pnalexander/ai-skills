# ai-skills

A shared repo for AI prompts, skills, agents, and hooks that we've found useful on side projects. Currently Claude-focused, but Cursor, GPT, and others are fair game.

This is informal — if it works, throw it in. No polish required.

---

## What's here

```
.claude/
  skills/       # Claude Code slash commands (/skill-name)
  agents/       # Subagent definitions for specialised tasks
  hooks/        # Shell hooks that run automatically around tool calls
  settings.json # Shared Claude Code settings
```

### Skills

| Skill | What it does |
|---|---|
| `feature-start` | Create a feature branch, optionally linked to a GitHub issue |
| `issue-create` | Create a GitHub issue following project conventions |
| `pr-create` | Create a pull request following project conventions |
| `release-create-branch` | Create a release branch using semver auto-bump |
| `release-notes` | Draft and publish release notes from merged PRs |
| `db-migrate` | Guided Prisma schema migration (validate → migrate → regenerate client) |

### Agents

| Agent | What it does |
|---|---|
| `schema-design` | Proposes Prisma schema changes for a feature, following project conventions |

### Hooks

| Hook | What it does |
|---|---|
| `prisma-schema-hook.sh` | Runs automatically around schema-related tool calls |

---

## Using these in your project

Copy whatever's useful into your project's `.claude/` directory. Skills, agents, and hooks are all just markdown or shell files — edit them to match your project's conventions.

For skills, run them as slash commands in Claude Code: `/feature-start`, `/pr-create`, etc.

---

## Contributing

Open a PR or just push to main — this is a low-ceremony repo. If something worked well for you on a project, share it. If something is too project-specific to be generally useful, either generalise it or note the assumptions clearly in the file.

A few loose guidelines:
- Put Claude stuff under `.claude/`, Cursor stuff under `.cursor/`, etc.
- Keep skill/agent prompts self-contained so they work without extra context
- Note any hard dependencies (specific tools, CLIs, project structure) at the top of the file

---

## Future `.gitignore` considerations

As this grows, you'll likely want to ignore:

```gitignore
# Local overrides — personal tweaks that shouldn't be shared
.claude/settings.local.json
.cursor/settings.local.json

# Secrets accidentally dropped into prompts or hooks
*.env
.env*
secrets/

# OS noise
.DS_Store
Thumbs.db

# If anyone starts adding runnable scripts with build artifacts
node_modules/
__pycache__/
*.pyc
dist/
```
