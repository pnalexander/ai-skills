---
name: release-notes
description: Draft and publish release notes from merged PRs into a release branch
argument-hint: "[branch|version] [--dry-run] (e.g., release/v0.1.0 or v0.1.0 — omit to auto-detect)"
disable-model-invocation: true
allowed-tools: Bash(gh *), Bash(git fetch *), Bash(git rev-parse *), Bash(git branch *), Bash(git remote *)
---

# Generate Release Notes

Draft release notes from PRs merged into a release branch, categorized by conventional commit type. Once approved, update the release PR body and create/update `CHANGELOG.md`.

## Flags

- `--dry-run` — Only generate and display the release notes draft. Do not write anything. Prompt the user with an option to proceed with writing after review.

## Steps

0. **Parse arguments:**
   Check if `$ARGUMENTS` contains `--dry-run`. If present, set dry-run mode and strip the flag before parsing the remaining arguments.

   Parse the remaining argument for a release branch or version:
   - If the argument looks like a branch name (e.g., `release/v0.1.0`), use it directly.
   - If the argument looks like a version (e.g., `v0.1.0` or `0.1.0`), normalize to `release/vMAJOR.MINOR.PATCH` format.
   - If no argument is provided, auto-detect in step 1.

1. **Determine the release branch:**
   If no branch was provided in arguments:
   - Check the current branch: `git rev-parse --abbrev-ref HEAD`. If it matches `release/v*`, use it.
   - Otherwise, fetch and find the latest remote release branch:
     ```
     git fetch origin
     git branch -r --list 'origin/release/v*'
     ```
     Use the latest one by semver sorting, stripping the `origin/` prefix.
   - If no release branch is found, report an error and stop.

   Extract the version number from the branch name (e.g., `release/v0.1.0` → `0.1.0`).

2. **Fetch merged PRs:**
   ```
   gh pr list --base <release-branch> --state merged --json title,number
   ```
   If no merged PRs are found, inform the user and stop.

3. **Categorize PRs by type prefix:**
   Parse each PR title using the `type(scope): description (#issue)` convention. Extract the type prefix, scope, description, and any trailing issue reference from each title.

   Apply this category mapping:

   | PR type prefix | Scope | Category |
   |---|---|---|
   | `feat` | anything except `skills` | **Features** |
   | `feat` | `skills` | **Maintenance** |
   | `fix` | any | **Fixes** |
   | `chore` | any | **Maintenance** |
   | `docs` | any | **Maintenance** |
   | `refactor` | any | **Maintenance** |
   | `test` | any | *(omit entirely)* |

   For each categorized PR, format a bullet point:
   - Extract the description portion from the PR title (everything after `type(scope): ` or `type: `).
   - Capitalize the first letter of the description.
   - If the description already contains an issue reference like `(#N)` at the end and the issue number differs from the PR number, show both: `(#issue, #PR)`. If they are the same, show just `(#N)`.
   - If the description has no issue reference, append `(#PR)`.

   Sort categories in this order: **Features**, **Fixes**, **Maintenance**. Within each category, sort entries by PR number ascending.

   If a PR title does not match the conventional format (no recognized type prefix), place it under **Maintenance**.

4. **Format the release notes draft:**
   Use Keep a Changelog format:
   ```
   ## [X.Y.Z] - YYYY-MM-DD

   ### Features
   - Description of feature (#N)

   ### Fixes
   - Description of fix (#N)

   ### Maintenance
   - Description of maintenance item (#N)
   ```

   Use today's date in ISO 8601 format (`YYYY-MM-DD`). Omit any category section that has no entries.

5. **Present draft to user:**
   Display the formatted release notes.

   - **If `--dry-run`:** Use AskUserQuestion with options: "Write release notes" and "Done". If "Done", stop. If "Write release notes", continue to step 6.
   - **Otherwise:** Use AskUserQuestion with options: "Approve and write", "Edit an entry", "Remove an entry", and "Cancel".
     - If "Edit an entry": Use AskUserQuestion to ask which entry to edit (show a numbered list of all entries across categories). Then ask for the replacement text. Re-format and re-display the draft. Loop back to the confirmation prompt.
     - If "Remove an entry": Use AskUserQuestion to ask which entry to remove (show a numbered list). Remove it, re-format, and re-display. Loop back to the confirmation prompt.
     - If "Cancel": Stop without writing anything.
     - If "Approve and write": Continue to step 6.

6. **Find the release PR:**
   ```
   gh pr list --head <release-branch> --base main --state open --json number,url
   ```
   If an open PR is found, capture its number for step 7. If no open PR exists, inform the user that the PR body update will be skipped.

7. **Update the release PR body:**
   If a release PR was found in step 6, update its body.

   Determine `{owner}/{repo}` from the remote origin URL:
   ```
   git remote get-url origin
   ```
   Parse `owner/repo` from either SSH (`git@github.com:owner/repo.git`) or HTTPS (`https://github.com/owner/repo.git`) format.

   Format the PR body using the project's standard template:
   ```
   ## Summary
   <release notes content from step 4, without the ## [version] - date heading>

   ## Release Target
   vX.Y.Z
   ```

   Update the PR:
   ```
   gh api repos/{owner}/{repo}/pulls/<pr-number> -X PATCH -f body="$(cat <<'EOF'
   <formatted body>
   EOF
   )"
   ```

8. **Create or update CHANGELOG.md:**
   Check if `CHANGELOG.md` exists at the project root.

   **If it does not exist:** Create it with this content:
   ```
   # Changelog

   All notable changes to this project will be documented in this file.

   The format is based on [Keep a Changelog](https://keepachangelog.com/),
   and this project adheres to [Semantic Versioning](https://semver.org/).

   <release notes from step 4>
   ```

   **If it already exists:** Read the file and insert the new release notes block above any existing version entries (before the first `## [` line), with a blank line separator between entries.

   Write the file using the Write tool.

9. **Report result:**
   Summarize what was done:
   - Number of PRs categorized and included
   - Whether the release PR body was updated (include the PR URL)
   - Whether `CHANGELOG.md` was created or updated
   - Remind the user to review and commit the `CHANGELOG.md` changes

## Important

- Never push directly to `main` or `release/*` branches.
- Never construct chained commands (using `&&`) that push to protected branches.
- The `test` type prefix is always excluded from release notes.
- The `feat(skills)` scope is categorized as Maintenance, not Features, since skill changes are internal tooling.
- Use `gh api` for updating the PR body to handle special characters safely.
- Always confirm with the user before writing any changes.
