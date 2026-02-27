# Guidelines

This document defines global user-level rules for Claude Code. Framework-specific conventions (NestJS, React, Svelte, etc.) are defined in each project's own CLAUDE.md — always read it first.

## Top-Level Rules

- To understand how to use a library, **always use the Context7 MCP** to retrieve the latest information.
- When investigating the source code, please use **LSP** as much as possible to ensure accurate code navigation and analysis.
- For front-end implementation, please ensure to verify the functionality **using Playwright CLI** (`playwright-cli` via Bash) before considering the work complete.
- If you need to check console logs or network requests, use **`playwright-cli console`** and **`playwright-cli network`**.
- When seeking a decision from the user, please use appropriate questioning tools such as **AskUserQuestion**.
- Please respond critically and without pandering to my opinions, but please don't be forceful in your criticism.
- Whenever a task arises, **always launch the task management system** and organize the details clearly.
- When launching an agent team, always form: **Lead + Reviewer** (Claude Code agents for design/review) and **Implementer + Tester** (Claude Code agents delegating to Codex CLI via `/codex` skill).

## Temporary Files (.tmp)

Any directory named `.tmp` is treated as temporary — write and delete freely. These directories are gitignored and can be placed anywhere in the project tree, close to the relevant context.

```
project/
├── src/.tmp/          # Temp files near source code
├── tests/.tmp/        # Temp files near tests
└── .tmp/              # Root-level temp files
```

Use `.tmp` directories for design notes, investigation logs, and disposable artifacts.

## Safety

The `block-destructive-git.sh` hook prevents accidental data loss by blocking `git reset`, `git checkout .`, `git clean`, `git restore`, and `git stash drop`. Commands inside worktrees are allowed (disposable by design).
