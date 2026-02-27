#!/bin/bash
# Block destructive git commands to prevent accidental data loss.
# Blocks: git reset, git checkout ., git clean, git restore, git stash drop
# Allows all commands inside worktrees (disposable by design).

INPUT=$(cat /dev/stdin)
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['tool_input']['command'])" 2>/dev/null)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Worktree detection: git-dir and git-common-dir differ inside a worktree
GIT_DIR=$(git rev-parse --git-dir 2>/dev/null)
GIT_COMMON=$(git rev-parse --git-common-dir 2>/dev/null)
if [ -n "$GIT_DIR" ] && [ -n "$GIT_COMMON" ] && [ "$GIT_DIR" != "$GIT_COMMON" ]; then
  exit 0
fi

REASON=""

if echo "$COMMAND" | grep -qE 'git\s+reset(\s|$)'; then
  REASON="git reset is blocked. This would discard changes."
elif echo "$COMMAND" | grep -qE 'git\s+checkout\s+(\.|--\s*\.)'; then
  REASON="git checkout . is blocked. Uncommitted changes would be lost."
elif echo "$COMMAND" | grep -qE 'git\s+checkout\s+--\s+'; then
  REASON="git checkout -- <file> is blocked. Only allowed with explicit user approval."
elif echo "$COMMAND" | grep -qE 'git\s+clean(\s|$)'; then
  REASON="git clean is blocked. Untracked files would be deleted."
elif echo "$COMMAND" | grep -qE 'git\s+restore(\s|$)'; then
  REASON="git restore is blocked. Only allowed with explicit user approval."
elif echo "$COMMAND" | grep -qE 'git\s+stash\s+drop'; then
  REASON="git stash drop is blocked. Stash contents would be lost."
else
  exit 0
fi

python3 -c "
import json
print(json.dumps({
    'hookSpecificOutput': {
        'hookEventName': 'PreToolUse',
        'permissionDecision': 'deny',
        'permissionDecisionReason': '$REASON'
    }
}))
"
