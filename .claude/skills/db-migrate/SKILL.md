---
name: db-migrate
description: Guided Prisma schema migration workflow — validates, migrates, and regenerates the client
argument-hint: "[migration-name] (e.g., add-user-avatar)"
disable-model-invocation: true
allowed-tools: Bash(git diff *), Bash(npx prisma *)
---

# Run Prisma Migration

Guided Prisma schema change and migration workflow that prevents common mistakes like forgetting to regenerate the client.

## Steps

0. **Parse arguments:**
   If `$ARGUMENTS` is provided, use it as the migration name. Otherwise, it will be prompted in a later step.

1. **Check for schema changes:**
   ```
   git diff prisma/schema.prisma
   git diff --cached prisma/schema.prisma
   ```
   Check both staged and unstaged changes. Also check for untracked schema file changes:
   ```
   git diff HEAD -- prisma/schema.prisma
   ```
   If there are no changes to `prisma/schema.prisma`, inform the user that there are no pending schema changes and stop. This skill is for running migrations after the schema has been edited.

2. **Show the diff and confirm:**
   Display the schema diff to the user. Use AskUserQuestion to confirm they want to proceed with the migration, with options "Yes, migrate" and "Cancel".

3. **Validate the schema:**
   ```
   npx prisma validate
   ```
   If validation fails, show the errors and stop. The user needs to fix the schema before migrating.

4. **Prompt for migration name (if not provided):**
   If no migration name was provided in `$ARGUMENTS`, use AskUserQuestion to ask the user for a short, descriptive migration name (e.g. `add-user-avatar`, `make-email-optional`). The name should be lowercase kebab-case.

5. **Run the migration:**
   ```
   npx prisma migrate dev --name <migration-name>
   ```
   This creates the migration SQL file and applies it to the development database.

6. **Regenerate the Prisma client:**
   ```
   npx prisma generate
   ```
   This ensures the TypeScript client reflects the new schema.

7. **Report result:**
   Summarize what happened:
   - Migration name
   - Remind the user to commit the new migration files in `prisma/migrations/` along with the updated `prisma/schema.prisma`

## Project Context

- Schema: `prisma/schema.prisma`
- Prisma client singleton: `src/lib/prisma.ts`
- Existing migrations: `prisma/migrations/`
- Current models: `Lobby`, `LobbySetting`, `Movie`, `DrawnMovie`, `Vote`, `LobbyConnection`

## Important

- Always validate before migrating — this catches syntax errors and relation issues early.
- Always regenerate the client after migrating — skipping this causes TypeScript errors for new/changed fields.
- Never skip the schema change check — running `migrate dev` with no changes creates an empty migration.
