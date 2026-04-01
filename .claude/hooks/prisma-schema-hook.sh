#!/bin/bash
# PostToolUse hook: remind user to validate/migrate after schema changes

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ "$FILE_PATH" == *"schema.prisma" ]]; then
  echo "Schema changed — run 'npx prisma validate' to check, then '/db/migrate' when ready."
fi

exit 0
