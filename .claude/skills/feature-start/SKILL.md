---
name: feature-start
description: Create a feature branch, optionally linked to a GitHub issue
argument-hint: "[issue-number] [description] [--worktree] [--base release/vX.Y.Z]"
disable-model-invocation: true
allowed-tools: Bash(gh *), Bash(git fetch *), Bash(git checkout *), Bash(git log *), Bash(git branch *), Bash(git rev-parse *), Bash(git worktree *), Bash(npm install*), Bash(npx prisma *), Bash(cp *)
---

# Start Feature Branch

Create a feature branch following the project's git conventions, optionally linked to a GitHub issue.

## Steps

0. **Parse arguments:**
   First, extract flags from `$ARGUMENTS`:
   - If `--worktree` is present, set the worktree flag to true and remove it from the argument string.
   - If `--base <branch>` is present, capture the branch value and remove both the flag and its value from the argument string.

   Then parse the remaining string for issue number and description:
   - If the remaining string starts with an integer, that is the issue number. Everything after it is the description.
   - If the remaining string does not start with an integer, there is no issue number. The entire remaining string is the description.
   - Either or both may be absent.

1. **Fetch latest refs:**
   ```
   git fetch origin
   ```

2. **Gather info based on arguments:**

   **If an issue number was provided:**
   - Fetch the issue title and labels:
     ```
     gh issue view <N> --json title,labels
     ```
   - Derive the branch type from labels:
     - `enhancement` label -> `feat`
     - `bug` label -> `fix`
     - Any other labels or no labels -> `chore`
   - If no description was provided in `$ARGUMENTS`, slugify the issue title to use as the description (lowercase, non-alphanumeric characters replaced with hyphens, collapse consecutive hyphens, trim leading/trailing hyphens).
   - Use AskUserQuestion to let the user confirm or override the derived type. Show the issue title, detected type, and proposed description. Offer the detected type as the recommended first option, plus the other standard types (`feat`, `fix`, `chore`) as alternatives.

   **If no issue number was provided:**
   - A description is required. If the remaining argument string is empty, use AskUserQuestion to ask the user for a short description.
   - Use AskUserQuestion to ask the user to pick a branch type (`feat`, `fix`, `chore`).

3. **Compose branch name:**
   - Slugify the description: lowercase, replace non-alphanumeric characters with hyphens, collapse consecutive hyphens, trim leading/trailing hyphens, truncate to ~50 characters (break at a hyphen boundary if possible).
   - With issue: `type/issue-N-short-description`
   - Without issue: `type/short-description`

4. **Determine base branch:**
   - **If `--base` was provided**, validate that the branch exists on the remote:
     ```
     git branch -r --list 'origin/<base>'
     ```
     If it doesn't exist, report an error and stop. If it exists, use it as the base branch and skip the remaining auto-detection logic below.
   - If the current branch (`git rev-parse --abbrev-ref HEAD`) matches `release/v*`, use it as the base.
   - Otherwise, look for the latest remote release branch:
     ```
     git branch -r --list 'origin/release/v*'
     ```
     If found, use the latest one (by semver sorting) as the base, stripping the `origin/` prefix.
   - If no release branch exists, fall back to `main`.

5. **Confirm:**
   Use AskUserQuestion to show the user:
   - The full branch name
   - The base branch

   **If `--worktree` is set**, also display:
   - The worktree path that will be created (see step 6 for path derivation)
   - That `npm install` and `npx prisma generate` will run in the worktree
   - That `.env` will be copied (if it exists in the main repo root)

   Ask the user to confirm before proceeding.

6. **Create branch:**

   **Without `--worktree`** (default):
   ```
   git checkout -b <branch-name> origin/<base-branch>
   ```

   **With `--worktree`**:

   1. Derive the worktree path:
      - Project name = basename of the current working directory (e.g., `cinemix`)
      - Worktree dir name = branch name with `/` replaced by `-`, suffixed with the base branch version when the base is a release branch (e.g., branch `feat/issue-12-lobby-chat` targeting `release/v0.2.0` -> dir `feat-issue-12-lobby-chat-v0.2.0`). If the base is `main` (no release branch), omit the version suffix.
      - Full path: `../worktrees/<project-name>/<worktree-dir-name>`
      - Note: The branch name and worktree directory name are independent — `git worktree add -b` accepts them as separate arguments.

   2. Check if the worktree path already exists. If it does, report the conflict and stop.

   3. Create the worktree and branch in one command:
      ```
      # Example: branch=feat/issue-12-lobby-chat, base=release/v0.2.0
      git worktree add -b feat/issue-12-lobby-chat \
        ../worktrees/cinemix/feat-issue-12-lobby-chat-v0.2.0 \
        origin/release/v0.2.0
      ```

   4. Copy `.env` to the worktree (if `.env` exists in the main repo root):
      ```
      cp .env <worktree-path>/.env
      ```

   5. Install dependencies in the worktree:
      ```
      npm install --prefix <worktree-path>
      ```

   6. Generate Prisma client in the worktree:
      ```
      npx prisma generate --schema <worktree-path>/prisma/schema.prisma
      ```

7. **Report result:**

   **Without `--worktree`**: Confirm the branch name was created and is checked out, and that it's ready for work.

   **With `--worktree`**: Report:
   - The branch name created
   - The base branch it's tracking
   - The full absolute path to the worktree
   - That dependencies are installed and ready
   - Remind the user to `cd <worktree-path>` or open a new Claude Code session there

## Important

- Branch names must follow the convention in `docs/CONTRIBUTING.md`: `type/issue-N-short-description` or `type/short-description`.
- Valid types are `feat`, `fix`, and `chore`.
- Always base the new branch on a remote ref (`origin/<base>`) to ensure it starts from the latest remote state.
- Worktrees share the `.git` directory with the main repo. Operations like `git fetch` in either location update both.
