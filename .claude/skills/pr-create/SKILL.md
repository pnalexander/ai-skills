---
name: pr-create
description: Create a pull request following project PR title and body conventions
argument-hint: "[--base <branch>] (e.g., --base main)"
disable-model-invocation: false
allowed-tools: Bash(gh *), Bash(git fetch *), Bash(git checkout *), Bash(git log *), Bash(git branch *), Bash(git rev-parse *), Bash(git diff *), Bash(git push *), Bash(git remote *)
---

# Create Pull Request

Create a pull request following the project's PR title convention (`type(scope): short description (#issue)`) and structured body format.

## Steps

0. **Parse arguments:**
   Check `$ARGUMENTS` for a `--base <branch>` flag. If present, use it as the base branch override. Strip the flag before processing any remaining arguments.

1. **Fetch latest refs:**
   ```
   git fetch origin
   ```

2. **Parse current branch name:**
   Get the current branch via `git rev-parse --abbrev-ref HEAD`. Parse it to extract:
   - `type` — the prefix before the first `/` (e.g. `feat`, `fix`, `chore`)
   - `issue` — the number after `issue-` if present (e.g. `issue-12-lobby-chat` → `12`)
   - `description` — the slug after the issue number, or the entire slug after `type/` if no issue (e.g. `lobby-chat` or `cleanup-imports`)

   If the current branch is `main` or `release/*`, stop with an error — PRs should be created from feature branches.

3. **Determine base branch:**
   - If `--base` was provided in arguments, use that.
   - If the current branch is a feature/fix/chore branch (not a release branch):
     1. Look for remote release branches: `git branch -r --list 'origin/release/v*'`
     2. If found, use the latest one (by semver sorting), stripping the `origin/` prefix.
     3. Otherwise, fall back to `main`.
   - If the current branch is a `release/v*` branch, target `main`.

4. **Summarize changes:**
   Run these commands to understand what the PR includes:
   ```
   git log origin/<base>..HEAD --oneline
   git diff origin/<base>...HEAD --stat
   ```
   These provide the commit list and file-level change summary.

5. **Auto-generate PR title:**
   Compose the title in `type(scope): short description (#issue)` format:
   - `type` — from the branch name.
   - `scope` — infer from the primary directory changed in the diff stat:
     - Changes mostly in `src/app/api/` → `api`
     - Changes mostly in `src/app/lobby/` → `lobby`
     - Changes mostly in `prisma/` → `db`
     - Changes mostly in `.claude/` → `skills`
     - Changes mostly in `docs/` → `docs`
     - Otherwise, pick the most-changed top-level directory under `src/`, or omit scope if unclear.
   - `description` — convert the branch slug to natural language (replace hyphens with spaces).
   - `(#issue)` — include if an issue number was parsed from the branch name, omit otherwise.

   Examples:
   - `feat(lobby): add chat (#12)`
   - `chore(skills): add feature start skill`

6. **Auto-generate PR body:**
   Use this template:
   ```
   ## Summary
   - <bullet points derived from commit messages>

   ## Test plan
   - [ ] <checklist items — generate from the change summary>

   ## Release Target
   <version>
   ```
   Derive summary bullets from the commit messages in step 4. Generate test plan items based on what changed (e.g. "Verify new API route returns expected response", "Test skill invocation with various arguments").

   For the release target, derive it automatically from the base branch determined in step 3:
   - If base matches `release/v*`, extract the version (e.g., `release/v0.2.0` → `v0.2.0`).
   - If base is `main`, use "Next release".

7. **Confirm with user:**
   Use AskUserQuestion to show the user:
   - The PR title
   - The base branch
   - The PR body

   Offer options: "Create PR", "Edit title", "Edit body", "Cancel". If the user chooses to edit, ask for the updated text and re-confirm.

8. **Push branch if needed:**
   Check if the branch has an upstream remote:
   ```
   git rev-parse --abbrev-ref --symbolic-full-name @{u}
   ```
   If this fails (no upstream), push with:
   ```
   git push -u origin <branch>
   ```

9. **Create the PR:**
   ```
   gh pr create --base <base> --title "<title>" --body "<body>"
   ```
   Use a HEREDOC for the body to preserve formatting.

10. **Report result:**
    Show the PR URL and confirm it was created successfully.

## Important

- Never push directly to `main` or `release/*` branches — this skill creates PRs targeting them.
- Never construct chained commands (using `&&`) that push to protected branches.
- PR title must follow the format in `docs/CONTRIBUTING.md`: `type(scope): short description (#issue)`.
- Always push the branch before creating the PR if it has no upstream.
