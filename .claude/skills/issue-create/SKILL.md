---
name: issue-create
description: Create a GitHub issue following project title and label conventions
argument-hint: "[type] [title] (e.g., feat add lobby chat)"
disable-model-invocation: false
allowed-tools: Bash(gh *), Bash(git fetch *), Bash(git branch *)
---

# Create GitHub Issue

Create a GitHub issue following the project's title convention (`type(scope): description`) and structured body format.

## Steps

0. **Parse arguments:**
   - If `$ARGUMENTS` starts with a known type (`feat`, `fix`, `chore`, `docs`), extract it as the type and treat the rest as the title.
   - If it doesn't start with a known type, treat the entire string as the title (type will be prompted).
   - Either or both may be absent.

1. **Gather info:**
   - If no type was parsed, use AskUserQuestion to ask the user to pick one (`feat`, `fix`, `chore`, `docs`).
   - If no title was provided, use AskUserQuestion to ask for a short title.

2. **Auto-assign label based on type:**

   | Type | Label |
   |------|-------|
   | `feat` | `enhancement` |
   | `fix` | `bug` |
   | `chore` | `maintenance` |
   | `docs` | `documentation` |

3. **Compose issue title:**
   Format: `type(scope): description` (matching PR title convention from `docs/CONTRIBUTING.md`).
   - Use AskUserQuestion to ask the user for a scope, offering common scopes (`lobby`, `api`, `db`, `skills`, `docs`) plus an option to omit scope.
   - If scope is omitted: `type: description`
   - If scope is provided: `type(scope): description`

4. **Determine release target:**
   - Run `git fetch origin` to get latest refs.
   - List remote release branches: `git branch -r --list 'origin/release/v*'`
   - **If release branches exist:** Use AskUserQuestion offering each branch version (e.g., `v0.2.0`, `v0.3.0`) sorted by semver as options, plus a "None" option to skip.
   - **If no release branches exist:** Use AskUserQuestion to ask the user for a target version string, with an option to skip.

5. **Compose issue body:**
   Use AskUserQuestion to ask the user to describe:
   - **Context** — what's the problem or need?
   - **Goal** — what should change?

   Format into the template:
   ```
   ## Context
   <user-provided context>

   ## Goal
   <user-provided goal>

   ## Release Target
   <version>
   ```

   If the user chose "None" / skipped in step 4, omit the `## Release Target` section entirely.

6. **Confirm with user:**
   Show the full issue preview: title, label, release target, and body.
   Offer options: "Create issue", "Edit title", "Edit body", "Cancel".
   If user edits, re-prompt for the updated content and re-confirm.

7. **Create the issue:**
   ```
   gh issue create --title "<title>" --label "<label>" --body "$(cat <<'EOF'
   <body>
   EOF
   )"
   ```
   Use a HEREDOC for the body to preserve formatting.

8. **Report result:**
   Show the issue URL and number. Mention the label that was applied and the release target (if set).

## Important

- Issue titles must follow the format in `docs/CONTRIBUTING.md`: `type(scope): description` or `type: description`.
- Valid types are `feat`, `fix`, `chore`, and `docs`.
- Always apply the matching label so issues are properly categorized.
