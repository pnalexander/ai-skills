---
name: release-create-branch
description: Create a new release branch from main using semantic versioning
argument-hint: "[version] [--dry-run] (e.g., v0.2.0 — omit to auto-bump minor)"
disable-model-invocation: true
allowed-tools: Bash(gh *), Bash(git fetch *), Bash(git checkout *), Bash(git log *), Bash(git branch *)
---

# Create Release Branch

Create a new release branch from `main` following the `release/vMAJOR.MINOR.PATCH` convention.

## Flags

- `--dry-run` — Only compute and display the branch name without creating it. Prompt the user with an option to proceed with actual creation.

## Steps

0. **Parse arguments:**
   Check if `$ARGUMENTS` contains `--dry-run`. If present, set dry-run mode and strip the flag before parsing the remaining arguments for a version number.

1. **Fetch latest main:**
   ```
   git fetch origin main
   ```

2. **Determine version:**
   - If a version argument was provided (`$ARGUMENTS`), use it. Strip the `v` prefix if present for parsing, then normalize to `vMAJOR.MINOR.PATCH` format. Validate it is a valid semver.
   - If no argument was provided, auto-detect the previous version using this priority:
     1. Check for existing `release/v*` branches on the remote (`git branch -r --list 'origin/release/v*'`).
     2. If none exist (release branches are deleted after merging), find the most recent `release/v*` merge commit in main's history: `git log origin/main --merges --oneline --grep="release/v"`. Parse the version from the merge commit message.
     3. If neither source yields a version, default to `v0.1.0`.
   - Bump the **minor** version by 1 and reset patch to 0 (e.g., `v0.1.0` -> `v0.2.0`).

3. **Confirm or dry-run:**
   - **If `--dry-run`:** Report the computed branch name (`release/vX.Y.Z`) and stop. Then use AskUserQuestion to offer the user a choice: "Create this branch now?" with options "Yes, create it" and "No, done". If they choose yes, continue to step 4. If no, stop.
   - **Otherwise:** Use AskUserQuestion to confirm the version before proceeding. Show the version, that the branch will be created from `origin/main`, and the full branch name.

4. **Create the branch on GitHub (do NOT use git push):**
   Get the SHA of `origin/main` and create the branch via the GitHub API:
   ```
   gh api repos/{owner}/{repo}/git/refs -f ref="refs/heads/release/vX.Y.Z" -f sha="<sha>"
   ```
   Determine `{owner}/{repo}` from the remote origin URL.

5. **Fetch and checkout locally:**
   ```
   git fetch origin release/vX.Y.Z
   git checkout release/vX.Y.Z
   ```

6. **Report result:** Tell the user the branch name and confirm it's ready for feature branches to PR into.

## Important

- NEVER use `git push` to create the release branch — always use `gh api`.
- The branch must always be created from `main`, not from another release branch.
- Version format must be `release/vMAJOR.MINOR.PATCH` (always include the `v` prefix).
