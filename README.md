# Claude Code Settings Best Practices

English | [日本語](./README_ja.md)

A repository collecting best practices for Claude Code settings and customization. We will continue to update and improve this repository to make it even better.

**Note:** Some settings in this repository are specifically configured for Japanese users. Please use LLM to translate and adapt them appropriately to your environment.

The configuration files in this repository are designed to be placed under `~/.claude/` directory. By placing these configuration files in the appropriate locations, you can customize Claude Code's behavior and build an efficient development environment.

## Project Structure

```
claude-code-settings/
├── .mcp.json          # MCP servers configuration file
├── .textlintrc.json   # textlint configuration file
├── CLAUDE.md          # Global user guidelines for ~/.claude/ placement
├── LICENSE            # MIT License file
├── README.md          # This file (English)
├── README_ja.md       # Japanese version
├── agents/            # Custom agent definitions
│   ├── backend-design-expert.md           # Backend/API design expert
│   ├── backend-implementation-engineer.md # Framework-agnostic backend implementation
│   ├── frontend-design-expert.md          # Frontend design reviewer
│   └── frontend-implementation-engineer.md # Framework-agnostic frontend implementation
├── settings.json      # Claude Code configuration file
├── skills/            # Skill definitions
│   ├── bug-investigation/
│   │   └── SKILL.md   # Bug investigation and analysis skill
│   ├── code-review/
│   │   └── SKILL.md   # Comprehensive code review skill (PR review + self-review + quality check)
│   ├── codex/
│   │   └── SKILL.md   # Codex CLI delegation skill for implementation/review/testing
│   ├── design-principles/
│   │   └── SKILL.md   # Design system enforcement skill
│   ├── humanize-text/
│   │   └── SKILL.md   # AI-written Japanese text humanization skill
│   ├── kill-dev-process/
│   │   └── SKILL.md   # Dev process cleanup skill
│   ├── playwright-cli/
│   │   ├── SKILL.md   # Browser automation via Playwright CLI (token-efficient)
│   │   └── references/ # Detailed reference docs
│   └── backlog-api/
│       └── SKILL.md   # Backlog project management via REST API
├── hooks/             # Git safety hooks
│   └── block-destructive-git.sh  # Blocks destructive git commands
└── symlinks/          # External tools config files as symbolic links
    ├── claude.json    # Claude Code user stats and settings cache
    ├── ccmanager/     # → ~/.config/ccmanager (CCManager configuration)
    │   ├── config.json     # CCManager settings and command presets
    │   └── init_worktree.sh # Worktree post-creation hook script
    └── codex/         # → ~/.codex (Codex CLI configuration)
        ├── AGENTS.md  # Codex project guidelines
        ├── config.toml # Codex CLI configuration
        └── skills/    # Codex skills (synced from Claude Code skills)
            ├── bug-investigation/
            ├── code-review/
            ├── design-principles/
            ├── humanize-text/
            ├── kill-dev-process/
            └── playwright-cli/
```

## About the symlinks Folder

The `symlinks/` folder contains configuration files for various external tools related to Claude Code. Since Claude Code is frequently updated and configuration changes are common, having all configuration files centralized in one folder makes editing much easier. Even if related files are normally placed outside the `~/.claude/` directory, it's convenient to place them here as symbolic links for unified management.

In actual environments, these files are placed as symbolic links in specified locations.

```bash
# Link Claude Code configuration
ln -s /path/to/settings.json ~/.claude/settings.json

# Link ccmanager configuration
ln -s ~/.config/ccmanager ~/.claude/symlinks/ccmanager

# Link Codex configuration
ln -s ~/.codex ~/.claude/symlinks/codex
```

This allows configuration changes to be managed in the repository and shared across multiple environments.

### Codex Configuration (`symlinks/codex/`)

The `codex/` symlink contains Codex CLI configuration for use with `codex exec`:

- **`config.toml`** - Codex CLI settings including model selection, sandbox mode, MCP servers, and model providers
- **`AGENTS.md`** - Project guidelines that Codex follows (similar to CLAUDE.md but without Claude Code-specific rules like team formation)
- **`skills/`** - Codex-compatible versions of Claude Code skills (bug-investigation, code-review, design-principles, humanize-text, kill-dev-process, playwright-cli)

## Key Features

### 1. Custom Agents and Skills

This repository provides specialized agents and skills to enhance Claude Code's capabilities:

**Agents** - Specialized agents for specific domains:
- Backend/API design and implementation expertise
- Frontend development and design review

**Skills** - User-invocable commands for common tasks:
- Code review with implementation guidelines
- Codex CLI delegation for implementation, review, and testing
- Design system enforcement
- Bug investigation with root cause analysis
- AI-written Japanese text humanization
- Dev process cleanup

### 2. Interactive Development Workflow

Leverage Claude Code's built-in Plan Mode and AskUserQuestion features to:
- Clarify requirements through interactive dialogue
- Create detailed implementation plans before coding
- Ensure alignment with user intent throughout development
- Systematically approach complex tasks

This interactive approach ensures specifications are clear before implementation begins.

### 3. Efficient Development Rules

- **Utilize parallel processing**: Multiple independent processes are executed simultaneously
- **Think in English, respond in Japanese**: Internal processing in English, user responses in Japanese
- **Leverage Context7 MCP**: Always reference the latest library information
- **Token-efficient browser automation**: Use Playwright CLI instead of MCP for ~4x token reduction
- **Thorough verification**: Always verify with Read after Write/Edit

### 4. Team Workflow with Codex CLI

Agent teams follow a structured formation:
- **Lead + Reviewer**: Claude Code agents handling design and review
- **Implementer + Tester**: Claude Code agents delegating to Codex CLI via `/codex` skill

This separation of concerns ensures quality through independent review and implementation roles.

## File Details

### CLAUDE.md

Defines global user guidelines. Contains the following content:

- **Top-Level Rules**: Basic operational rules including MCP usage, testing requirements, and team workflows
- Always use Context7 MCP for library information
- Use LSP for accurate code navigation and analysis
- Verify frontend functionality with Playwright CLI (`playwright-cli` via Bash)
- Use `playwright-cli console` and `playwright-cli network` for console logs and network requests
- Use AskUserQuestion for decision-making
- Use `.tmp` directories for temporary files (can be placed anywhere in the project tree)
- Respond critically without pandering, but not forcefully
- Always launch the task management system for tasks
- Team formation: Lead + Reviewer (Claude Code agents) and Implementer + Tester (Codex CLI via `/codex`)

### .mcp.json

Defines MCP (Model Context Protocol) servers available for use:

| Server | Description |
| --- | --- |
| **context7** | Up-to-date documentation and code examples for libraries |
| **chrome-devtools** | DevTools Protocol direct access (CPU/network emulation, etc.) |
| **sentry** | AI-powered error analysis with Seer, natural language issue search |

> **Note:** Browser automation uses **Playwright CLI** (`@playwright/cli`) instead of Playwright MCP for ~4x token reduction. See the `skills/playwright-cli/` skill for usage. Chrome DevTools MCP is kept for DevTools Protocol features not available through Playwright CLI.

### settings.json

Configuration file that controls Claude Code behavior:

#### Environment Variable Configuration (`env`)
```json
{
  "DISABLE_TELEMETRY": "1",                         // Disable telemetry
  "DISABLE_ERROR_REPORTING": "1",                   // Disable error reporting
  "DISABLE_BUG_COMMAND": "1",                       // Disable bug command
  "API_TIMEOUT_MS": "600000",                       // API timeout (10 minutes)
  "DISABLE_AUTOUPDATER": "0",                       // Auto-updater setting
  "CLAUDE_CODE_ENABLE_TELEMETRY": "0",              // Claude Code telemetry
  "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",  // Disable non-essential traffic
  "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"       // Enable experimental agent teams
}
```

#### Permission Configuration (`permissions`)

**allow (allowlist)**:
- File reading: `Read(**)`
- Writing to specific directories: `Write(src/**)`, `Write(docs/**)`, `Write(**/.tmp/**)`
- Package management: `npm`/`pnpm`/`yarn` install, test, build
- File operations: `rm`
- Basic shell commands: `ls`, `cat`, `head`, `tail`, `pwd`, `find`, `tree`, `mkdir`, `mv`
- Docker operations: `docker compose up -d --build`
- macOS notifications: `osascript -e`

**deny (blocklist)**:
- Dangerous commands: `sudo`, `rm`, `rm -rf`
- Git operations: `git push`, `git commit`, `git reset`, `git rebase`, `git rm`, `git clean`
- Security related: Reading `.env.*` files, `id_rsa`, `id_ed25519`, tokens, keys
- Writing sensitive files: `.env*`, `**/secrets/**`
- Network operations: `curl`, `wget`, `nc`
- Package removal: `npm uninstall`, `npm remove`
- Direct database operations: `psql`, `mysql`
> **Note:** `rm` appears in both allow and deny lists. Since deny takes precedence, `rm` commands require explicit approval.

#### Hook Configuration (`hooks`)

**PreToolUse** (Safety hooks before tool execution)
- `block-destructive-git.sh` blocks `git reset`, `git checkout .`, `git clean`, `git restore`, `git stash drop` to prevent accidental data loss. Commands inside worktrees are allowed.

**PostToolUse** (Automatic processing after tool use)
- Automatic Prettier formatting when editing JS/TS/JSON/TSX files

**Notification** (Notification settings - macOS)
- Display notifications with custom messages and titles using macOS notification system

**Stop** (Processing when work is completed)
- Display "作業が完了しました" (Work completed) notification

#### MCP Server Activation (`enabledMcpjsonServers`)

Controls which MCP servers defined in `.mcp.json` are activated.

- **context7** - Up-to-date documentation and code examples for libraries
- **chrome-devtools** - DevTools Protocol direct access
- **sentry** - AI-powered error analysis and issue search

#### Additional Configuration
- `cleanupPeriodDays`: 20 - Cleanup period for old data
- `enableAllProjectMcpServers`: true - Enable all project-specific MCP servers
- `language`: "Japanese" - Interface language
- `alwaysThinkingEnabled`: true - Always show thinking process
- `enabledPlugins`: Playwright CLI plugin + LSP plugins for enhanced code intelligence (rust-analyzer, typescript, pyright)

### Custom Agents (agents/)

Custom agents provide specialized capabilities for specific development tasks. These agents are automatically available when using Claude Code and can be invoked through the Task tool.

| Agent                              | Description                                                                                 |
| ---------------------------------- | ------------------------------------------------------------------------------------------- |
| `backend-design-expert`            | Code-agnostic backend/API expert for specification-first design and operational correctness |
| `backend-implementation-engineer`  | Framework-agnostic backend implementation with layered architecture (reads project CLAUDE.md)|
| `frontend-design-expert`           | Code-agnostic frontend reviewer for SPA/SSR apps, audits architecture and performance       |
| `frontend-implementation-engineer` | Framework-agnostic frontend implementation with component architecture (reads project CLAUDE.md)|

### Official Plugins

Claude Code provides official LSP (Language Server Protocol) plugins for enhanced code intelligence. These are configured in `settings.json` under `enabledPlugins`.

| Plugin               | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `rust-analyzer-lsp`  | Rust language server for code navigation and analysis      |
| `typescript-lsp`     | TypeScript/JavaScript language server                      |
| `pyright-lsp`        | Python language server for type checking and analysis      |

### Skills (skills/)

Skills are user-invocable commands that can be called directly using the `/skill-name` syntax.

| Skill                  | Description                                                                     |
| ---------------------- | ------------------------------------------------------------------------------- |
| `/bug-investigation`   | Systematically investigate bugs with root cause analysis and fix proposals      |
| `/code-review`         | Comprehensive code review combining PR review, self-review, and quality checks  |
| `/codex`               | Delegate tasks to Codex CLI for implementation, review, testing, or design consultation |
| `/design-principles`   | Enforce precise, minimal design system inspired by Linear, Notion, and Stripe   |
| `/humanize-text`       | Transform AI-written Japanese text into natural, human-like Japanese            |
| `/kill-dev-process`    | Kill orphaned dev servers, browsers, and port-hogging processes                 |
| `/playwright-cli`      | Token-efficient browser automation via Playwright CLI (replaces Playwright MCP) |
| `/backlog-api`         | Interact with Backlog project management via REST API (curl-based)              |

## Quick Setup (curl)

Download common settings into your project repository's `.claude/` directory. Run this from your project root.

> **Note:** Project-specific files (your own skills, customized settings.json, .mcp.json) are **not** affected — only common files (agents, hooks, shared skills) are overwritten.

### Download All Common Files

```bash
BASE="https://raw.githubusercontent.com/simount/claude-code-settings/main"
TARGET=".claude"

# Create necessary directories
mkdir -p "$TARGET"/{agents,hooks}
mkdir -p "$TARGET"/skills/{bug-investigation,code-review,codex,design-principles,humanize-text,kill-dev-process,playwright-cli/references,backlog-api}

# Download hooks
curl -o "$TARGET/hooks/block-destructive-git.sh" "$BASE/hooks/block-destructive-git.sh"
chmod +x "$TARGET/hooks/block-destructive-git.sh"

# Download agents
for f in backend-design-expert backend-implementation-engineer frontend-design-expert frontend-implementation-engineer; do
  curl -o "$TARGET/agents/$f.md" "$BASE/agents/$f.md"
done

# Download common skills
for skill in bug-investigation code-review codex design-principles humanize-text kill-dev-process backlog-api; do
  curl -o "$TARGET/skills/$skill/SKILL.md" "$BASE/skills/$skill/SKILL.md"
done

# Download playwright-cli skill + references
curl -o "$TARGET/skills/playwright-cli/SKILL.md" "$BASE/skills/playwright-cli/SKILL.md"
for ref in request-mocking running-code session-management storage-state test-generation tracing video-recording; do
  curl -o "$TARGET/skills/playwright-cli/references/$ref.md" "$BASE/skills/playwright-cli/references/$ref.md"
done

echo "Done. Review and merge settings.json and .mcp.json manually."
```

> **Note:** `settings.json` and `.mcp.json` are **not** downloaded automatically because they contain project-specific customizations. Merge changes from the source repository manually.

### Download Individual Files

If you only want specific files, you can download them individually:

```bash
BASE="https://raw.githubusercontent.com/simount/claude-code-settings/main"
TARGET=".claude"

# Example: Download only a specific agent
curl -o "$TARGET/agents/backend-design-expert.md" "$BASE/agents/backend-design-expert.md"

# Example: Download only a specific skill
mkdir -p "$TARGET/skills/code-review"
curl -o "$TARGET/skills/code-review/SKILL.md" "$BASE/skills/code-review/SKILL.md"
```

## Deployment to Project Repositories

This repository serves as the canonical source for shared Claude Code settings across the simount organization. Common settings are committed into each project repository's `.claude/` directory so that all team members receive updates via `git pull`.

### Workflow Overview

```
simount/claude-code-settings (canonical source)
        │
        │  One designated person merges & applies
        ▼
Each project repo .claude/ (committed, common + project-specific coexist)
        │
        │  git pull
        ▼
All team members get the update
```

### What Gets Deployed

Each project repository's `.claude/` directory contains both **common files** (from this repo) and **project-specific files**:

| Type | Examples |
| --- | --- |
| **Common** (from this repo) | `agents/`, `hooks/`, shared skills (bug-investigation, code-review, codex, design-principles, humanize-text, kill-dev-process, playwright-cli, backlog-api) |
| **Project-specific** (managed in each project) | Project's own skills, project-level settings.json, .mcp.json customizations |

### Deployment Process

A single designated person is responsible for both updating this repository and applying changes to project repositories.

1. **Update this repo** — Make changes to `simount/claude-code-settings` (merge upstream changes from `nokonoko1203/claude-code-settings` or add simount-specific improvements)
2. **Apply common files to each project** — Copy common files into the project repo's `.claude/` directory. Overwrite agents, hooks, and common skills. Manually merge `settings.json` and `.mcp.json` (these have project-specific customizations)
3. **Commit to the project repo** — The team gets the update via `git pull`

```bash
# Example: sync common files to a project repo
SOURCE="/path/to/claude-code-settings"
TARGET="/path/to/project-repo/.claude"

# Agents (full overwrite)
cp -r "$SOURCE/agents/" "$TARGET/agents/"

# Hooks (full overwrite)
cp -r "$SOURCE/hooks/" "$TARGET/hooks/"

# Common skills (by name, project-specific skills are untouched)
for skill in bug-investigation code-review codex design-principles humanize-text kill-dev-process backlog-api; do
  mkdir -p "$TARGET/skills/$skill"
  cp -r "$SOURCE/skills/$skill/" "$TARGET/skills/$skill/"
done
cp -r "$SOURCE/skills/playwright-cli/" "$TARGET/skills/playwright-cli/"

# settings.json, .mcp.json — manually merge (project-specific customizations exist)
echo "Review and merge settings.json and .mcp.json manually."
```

### Merging Upstream (nokonoko1203)

To see what simount has customized compared to upstream: [View diff on GitHub](https://github.com/simount/claude-code-settings/compare/nokonoko1203:main...simount:main)

```bash
# Initial setup (once)
git remote add upstream https://github.com/nokonoko1203/claude-code-settings.git

# Merge upstream changes
git fetch upstream
git merge upstream/main --no-edit

# View simount-specific changes locally
git diff upstream/main..main
git log upstream/main..main --oneline
```

> **Note:** `agents/backend-implementation-engineer.md` and `agents/frontend-implementation-engineer.md` have been significantly restructured (framework-agnostic). These will require manual conflict resolution when merging upstream. Other files should have minimal conflicts.

### User-Level Settings (`~/.claude/`)

User-level settings (personal `~/.claude/CLAUDE.md`, `~/.claude/settings.json`) are **out of scope** for this deployment workflow. Each developer manages their own user-level settings independently. The Quick Install section above can be used for personal setup if desired.

## References

- [Claude Code overview](https://docs.anthropic.com/en/docs/claude-code)
- [Model Context Protocol (MCP)](https://docs.anthropic.com/en/docs/mcp)
- [OpenAI Codex](https://openai.com/codex)
- [textlint](https://textlint.github.io/)
- [CCManager](https://github.com/kbwo/ccmanager)
- [Context7](https://context7.com/)
- [Playwright CLI](https://www.npmjs.com/package/@playwright/cli)

## License

This project is released under the MIT License.
