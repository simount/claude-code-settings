# Claude Code 設定ベストプラクティス

[English](./README.md) | 日本語

Claude Code の設定とカスタマイズに関するベストプラクティスを集めたリポジトリです。より良いものにするため、継続的に更新・改善していきます。

このリポジトリの設定ファイルは `~/.claude/` ディレクトリ配下に配置することを想定しています。設定ファイルを適切な場所に配置することで、Claude Code の動作をカスタマイズし、効率的な開発環境を構築できます。

## プロジェクト構造

```
claude-code-settings/
├── .mcp.json          # MCP サーバー設定ファイル
├── .textlintrc.json   # textlint 設定ファイル
├── CLAUDE.md          # ~/.claude/ に配置するグローバルユーザーガイドライン
├── LICENSE            # MIT ライセンスファイル
├── README.md          # 英語版 README
├── README_ja.md       # 日本語版 README（このファイル）
├── agents/            # カスタムエージェント定義
│   ├── backend-design-expert.md           # バックエンド/API 設計エキスパート
│   ├── backend-implementation-engineer.md # フレームワーク非依存バックエンド実装
│   ├── frontend-design-expert.md          # フロントエンド設計レビュアー
│   └── frontend-implementation-engineer.md # フレームワーク非依存フロントエンド実装
├── settings.json      # Claude Code 設定ファイル
├── skills/            # スキル定義
│   ├── bug-investigation/
│   │   └── SKILL.md   # バグ調査・分析スキル
│   ├── code-review/
│   │   └── SKILL.md   # 統合コードレビュースキル（PRレビュー + セルフレビュー + 品質チェック）
│   ├── codex/
│   │   └── SKILL.md   # Codex CLI 委譲スキル（実装/レビュー/テスト）
│   ├── design-principles/
│   │   └── SKILL.md   # デザインシステム適用スキル
│   ├── humanize-text/
│   │   └── SKILL.md   # AI 文章の自然な日本語化スキル
│   ├── kill-dev-process/
│   │   └── SKILL.md   # 開発プロセスクリーンアップスキル
│   ├── playwright-cli/
│   │   ├── SKILL.md   # Playwright CLI によるブラウザ自動化（トークン効率重視）
│   │   └── references/ # 詳細リファレンスドキュメント
│   └── backlog-api/
│       └── SKILL.md   # Backlog REST API 操作スキル
├── hooks/             # Git 安全フック
│   └── block-destructive-git.sh  # 破壊的 git コマンドをブロック
└── symlinks/          # 外部ツール設定ファイル（シンボリックリンク）
    ├── claude.json    # Claude Code ユーザー統計・設定キャッシュ
    ├── ccmanager/     # → ~/.config/ccmanager（CCManager 設定）
    │   ├── config.json     # CCManager 設定・コマンドプリセット
    │   └── init_worktree.sh # ワークツリー作成後フックスクリプト
    └── codex/         # → ~/.codex（Codex CLI 設定）
        ├── AGENTS.md  # Codex プロジェクトガイドライン
        ├── config.toml # Codex CLI 設定
        └── skills/    # Codex スキル（Claude Code スキルと同期）
            ├── bug-investigation/
            ├── code-review/
            ├── design-principles/
            ├── humanize-text/
            ├── kill-dev-process/
            └── playwright-cli/
```

## symlinks フォルダについて

`symlinks/` フォルダには、Claude Code に関連する各種外部ツールの設定ファイルが含まれています。Claude Code は頻繁に更新され、設定変更も多いため、すべての設定ファイルを1つのフォルダに集約することで編集が容易になります。関連ファイルが通常 `~/.claude/` ディレクトリ外に配置される場合でも、シンボリックリンクとしてここに配置することで一元管理できます。

実際の環境では、これらのファイルは指定された場所にシンボリックリンクとして配置されます。

```bash
# Claude Code 設定をリンク
ln -s /path/to/settings.json ~/.claude/settings.json

# ccmanager 設定をリンク
ln -s ~/.config/ccmanager ~/.claude/symlinks/ccmanager

# Codex 設定をリンク
ln -s ~/.codex ~/.claude/symlinks/codex
```

これにより、設定変更をリポジトリで管理し、複数の環境間で共有できます。

### Codex 設定（`symlinks/codex/`）

`codex/` シンボリックリンクには、`codex exec` で使用するための Codex CLI 設定が含まれます：

- **`config.toml`** - モデル選択、サンドボックスモード、MCP サーバー、モデルプロバイダーなどの Codex CLI 設定
- **`AGENTS.md`** - Codex が従うプロジェクトガイドライン（CLAUDE.md に類似するが、チーム編成など Claude Code 固有のルールは除外）
- **`skills/`** - Claude Code スキルの Codex 互換バージョン（bug-investigation、code-review、design-principles、humanize-text、kill-dev-process、playwright-cli）

## 主な機能

### 1. カスタムエージェントとスキル

このリポジトリは、Claude Code の機能を強化する専門エージェントとスキルを提供します：

**エージェント** - 特定ドメイン向けの専門エージェント：
- バックエンド/API の設計と実装の専門知識
- フロントエンド開発とデザインレビュー

**スキル** - 一般的なタスク向けのユーザー呼び出し可能なコマンド：
- 実装ガイドラインに基づくコードレビュー
- Codex CLI への実装・レビュー・テストの委譲
- デザインシステムの適用
- 根本原因分析を含むバグ調査
- AI 文章の自然な日本語化
- 開発プロセスのクリーンアップ

### 2. インタラクティブな開発ワークフロー

Claude Code の組み込み機能である Plan Mode と AskUserQuestion を活用して：
- 対話を通じて要件を明確化
- コーディング前に詳細な実装計画を作成
- 開発全体を通じてユーザーの意図との整合性を確保
- 複雑なタスクに体系的にアプローチ

このインタラクティブなアプローチにより、実装開始前に仕様を明確にできます。

### 3. 効率的な開発ルール

- **並列処理の活用**: 複数の独立したプロセスを同時に実行
- **英語で思考し、日本語で応答**: 内部処理は英語、ユーザーへの応答は日本語
- **Context7 MCP の活用**: 常に最新のライブラリ情報を参照
- **トークン効率的なブラウザ自動化**: MCP の代わりに Playwright CLI を使用し、トークン消費を約4分の1に削減
- **徹底した検証**: Write/Edit 後は必ず Read で確認

### 4. Codex CLI を活用したチームワークフロー

エージェントチームは以下の構成に従います：
- **Lead + Reviewer**: 設計とレビューを担当する Claude Code エージェント
- **Implementer + Tester**: `/codex` スキル経由で Codex CLI に委譲する Claude Code エージェント

この関心の分離により、独立したレビューと実装の役割を通じて品質を確保します。

## ファイル詳細

### CLAUDE.md

グローバルユーザーガイドラインを定義します。以下の内容が含まれます：

- **トップレベルルール**: MCP 使用、テスト要件、チームワークフローを含む基本的な運用ルール
- ライブラリ情報には常に Context7 MCP を使用
- コード調査には LSP を使用して正確なナビゲーションと分析を実現
- フロントエンド機能は Playwright CLI（`playwright-cli` via Bash）で検証
- コンソールログ・ネットワーク確認には `playwright-cli console` / `playwright-cli network` を使用
- 意思決定には AskUserQuestion を使用
- 一時ファイルは `.tmp` ディレクトリに保存（プロジェクト内のどこにでも配置可能）
- 批判的に応答し忖度しないが、強引な批判はしない
- タスク発生時は常にタスク管理システムを起動
- チーム編成: Lead + Reviewer（Claude Code エージェント）と Implementer + Tester（Codex CLI via `/codex`）

### .mcp.json

使用可能な MCP（Model Context Protocol）サーバーを定義します：

| サーバー | 説明 |
| --- | --- |
| **context7** | ライブラリの最新ドキュメントとコード例 |
| **chrome-devtools** | DevTools Protocol 直接アクセス（CPU/ネットワークエミュレーション等） |
| **sentry** | Seer AI によるエラー分析、自然言語 Issue 検索 |

> **注意:** ブラウザ自動化は **Playwright CLI**（`@playwright/cli`）を使用し、トークン消費を約4分の1に削減しています。`skills/playwright-cli/` スキルを参照してください。Chrome DevTools MCP は Playwright CLI では代替困難な DevTools Protocol 機能のために残しています。

### settings.json

Claude Code の動作を制御する設定ファイル：

#### 環境変数設定（`env`）
```json
{
  "DISABLE_TELEMETRY": "1",                         // テレメトリを無効化
  "DISABLE_ERROR_REPORTING": "1",                   // エラーレポートを無効化
  "DISABLE_BUG_COMMAND": "1",                       // バグコマンドを無効化
  "API_TIMEOUT_MS": "600000",                       // API タイムアウト（10分）
  "DISABLE_AUTOUPDATER": "0",                       // 自動更新設定
  "CLAUDE_CODE_ENABLE_TELEMETRY": "0",              // Claude Code テレメトリ
  "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",  // 非必須トラフィックを無効化
  "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"       // 実験的エージェントチーム機能を有効化
}
```

#### パーミッション設定（`permissions`）

**allow（許可リスト）**:
- ファイル読み取り: `Read(**)`
- 特定ディレクトリへの書き込み: `Write(src/**)`, `Write(docs/**)`, `Write(**/.tmp/**)`
- パッケージ管理: `npm`/`pnpm`/`yarn` の install, test, build
- ファイル操作: `rm`
- 基本的なシェルコマンド: `ls`, `cat`, `head`, `tail`, `pwd`, `find`, `tree`, `mkdir`, `mv`
- Docker 操作: `docker compose up -d --build`
- macOS 通知: `osascript -e`

**deny（拒否リスト）**:
- 危険なコマンド: `sudo`, `rm`, `rm -rf`
- Git 操作: `git push`, `git commit`, `git reset`, `git rebase`, `git rm`, `git clean`
- セキュリティ関連: `.env.*` ファイルの読み取り、`id_rsa`、`id_ed25519`、トークン、キー
- 機密ファイルへの書き込み: `.env*`, `**/secrets/**`
- ネットワーク操作: `curl`, `wget`, `nc`
- パッケージ削除: `npm uninstall`, `npm remove`
- 直接的なデータベース操作: `psql`, `mysql`
> **注意:** `rm` は allow と deny の両方に存在します。deny が優先されるため、`rm` コマンドには明示的な承認が必要です。

#### フック設定（`hooks`）

**PreToolUse**（ツール実行前の安全フック）
- `block-destructive-git.sh` が `git reset`、`git checkout .`、`git clean`、`git restore`、`git stash drop` をブロックし、意図しないデータ消失を防止。worktree 内のコマンドは許可。

**PostToolUse**（ツール使用後の自動処理）
- JS/TS/JSON/TSX ファイル編集時に Prettier で自動フォーマット

**Notification**（通知設定 - macOS）
- macOS 通知システムを使用してカスタムメッセージとタイトルで通知を表示

**Stop**（作業完了時の処理）
- 「作業が完了しました」通知を表示

#### MCP サーバー有効化（`enabledMcpjsonServers`）

`.mcp.json` で定義された MCP サーバーのうち、有効化するものを制御します。

- **context7** - ライブラリの最新ドキュメントとコード例
- **chrome-devtools** - DevTools Protocol 直接アクセス
- **sentry** - AI によるエラー分析と Issue 検索

#### その他の設定
- `cleanupPeriodDays`: 20 - 古いデータのクリーンアップ期間
- `enableAllProjectMcpServers`: true - すべてのプロジェクト固有 MCP サーバーを有効化
- `language`: "Japanese" - インターフェース言語
- `alwaysThinkingEnabled`: true - 常に思考プロセスを表示
- `enabledPlugins`: Playwright CLI プラグイン + コードインテリジェンス強化のための LSP プラグイン（rust-analyzer、typescript、pyright）

### カスタムエージェント（agents/）

カスタムエージェントは、特定の開発タスク向けの専門機能を提供します。これらのエージェントは Claude Code 使用時に自動的に利用可能になり、Task ツールを通じて呼び出せます。

| エージェント                       | 説明                                                                                           |
| ---------------------------------- | ---------------------------------------------------------------------------------------------- |
| `backend-design-expert`            | 仕様優先設計と運用正確性のためのコード非依存バックエンド/API エキスパート                      |
| `backend-implementation-engineer`  | フレームワーク非依存のバックエンド実装（レイヤードアーキテクチャ、プロジェクト CLAUDE.md 参照）|
| `frontend-design-expert`           | SPA/SSR アプリ向けのコード非依存フロントエンドレビュアー、アーキテクチャとパフォーマンスを監査 |
| `frontend-implementation-engineer` | フレームワーク非依存のフロントエンド実装（コンポーネントアーキテクチャ、プロジェクト CLAUDE.md 参照）|

### 公式プラグイン

Claude Code は、コードインテリジェンスを強化するための公式 LSP（Language Server Protocol）プラグインを提供しています。これらは `settings.json` の `enabledPlugins` で設定されます。

| プラグイン           | 説明                                              |
| -------------------- | ------------------------------------------------- |
| `rust-analyzer-lsp`  | Rust 言語サーバー（コードナビゲーション・分析）   |
| `typescript-lsp`     | TypeScript/JavaScript 言語サーバー                |
| `pyright-lsp`        | Python 言語サーバー（型チェック・分析）           |

### スキル（skills/）

スキルは `/skill-name` 構文で直接呼び出せるユーザー呼び出し可能なコマンドです。

| スキル                 | 説明                                                                                    |
| ---------------------- | --------------------------------------------------------------------------------------- |
| `/bug-investigation`   | バグを体系的に調査し、根本原因分析と修正提案を含むレポートを生成                        |
| `/code-review`         | PR レビュー、セルフレビュー、品質チェックを統合した包括的コードレビュー                 |
| `/codex`               | Codex CLI にタスクを委譲（実装、レビュー、テスト、設計コンサルテーション）              |
| `/design-principles`   | Linear、Notion、Stripe にインスパイアされた精密でミニマルなデザインシステムを適用       |
| `/humanize-text`       | AI が書いた日本語を自然な人間らしい日本語に書き換え                                     |
| `/kill-dev-process`    | 開発中に残った不要なサーバー、ブラウザ、ポート占有プロセスを停止                        |
| `/playwright-cli`      | Playwright CLI によるトークン効率的なブラウザ自動化（Playwright MCP の後継）            |
| `/backlog-api`         | Backlog REST API 経由のプロジェクト管理操作（curl ベース）                              |

## クイックセットアップ（curl）

プロジェクトリポジトリの `.claude/` ディレクトリに共通設定をダウンロードします。プロジェクトルートから実行してください。

> **注意:** プロジェクト固有のファイル（独自スキル、カスタマイズ済み settings.json、.mcp.json）は**影響を受けません** — 共通ファイル（agents、hooks、共通スキル）のみが上書きされます。

### 共通ファイルを一括ダウンロード

```bash
BASE="https://raw.githubusercontent.com/simount/claude-code-settings/main"
TARGET=".claude"

# 必要なディレクトリを作成
mkdir -p "$TARGET"/{agents,hooks}
mkdir -p "$TARGET"/skills/{bug-investigation,code-review,codex,design-principles,humanize-text,kill-dev-process,playwright-cli/references,backlog-api}

# 設定ファイルをダウンロード
curl -o "$TARGET/settings.json" "$BASE/settings.json"
curl -o "$TARGET/.mcp.json" "$BASE/.mcp.json"

# フックをダウンロード
curl -o "$TARGET/hooks/block-destructive-git.sh" "$BASE/hooks/block-destructive-git.sh"
chmod +x "$TARGET/hooks/block-destructive-git.sh"

# エージェントをダウンロード
for f in backend-design-expert backend-implementation-engineer frontend-design-expert frontend-implementation-engineer; do
  curl -o "$TARGET/agents/$f.md" "$BASE/agents/$f.md"
done

# 共通スキルをダウンロード
for skill in bug-investigation code-review codex design-principles humanize-text kill-dev-process backlog-api; do
  curl -o "$TARGET/skills/$skill/SKILL.md" "$BASE/skills/$skill/SKILL.md"
done

# playwright-cli スキル + リファレンスをダウンロード
curl -o "$TARGET/skills/playwright-cli/SKILL.md" "$BASE/skills/playwright-cli/SKILL.md"
for ref in request-mocking running-code session-management storage-state test-generation tracing video-recording; do
  curl -o "$TARGET/skills/playwright-cli/references/$ref.md" "$BASE/skills/playwright-cli/references/$ref.md"
done

echo "完了。git diff で変更を確認してください。"
```

> **ヒント:** ダウンロード後、`git diff` で変更を確認してください。設定ファイル（`settings.json`、`.mcp.json`）にはプロジェクト固有のカスタマイズが含まれる場合があります。コミット前に必要に応じてマージしてください。

### 個別ファイルのダウンロード

特定のファイルのみが必要な場合は、個別にダウンロードできます：

```bash
BASE="https://raw.githubusercontent.com/simount/claude-code-settings/main"
TARGET=".claude"

# 例: 特定のエージェントのみをダウンロード
curl -o "$TARGET/agents/backend-design-expert.md" "$BASE/agents/backend-design-expert.md"

# 例: 特定のスキルのみをダウンロード
mkdir -p "$TARGET/skills/code-review"
curl -o "$TARGET/skills/code-review/SKILL.md" "$BASE/skills/code-review/SKILL.md"
```

## プロジェクトリポジトリへのデプロイ

このリポジトリは、simount 組織全体で共有する Claude Code 設定の正規ソースです。共通設定は各プロジェクトリポジトリの `.claude/` ディレクトリにコミットし、チームメンバーは `git pull` で更新を受け取ります。

### ワークフロー概要

```
simount/claude-code-settings（正規ソース）
        │
        │  担当者1名がマージ・反映
        ▼
各プロジェクトリポ .claude/（コミット済み、共通+固有が混在）
        │
        │  git pull
        ▼
チームメンバー全員に適用
```

### デプロイ対象

各プロジェクトリポジトリの `.claude/` には**共通ファイル**（本リポジトリ由来）と**プロジェクト固有ファイル**が混在します:

| 種別 | 例 |
| --- | --- |
| **共通**（本リポジトリ由来） | `agents/`, `hooks/`, 共通スキル（bug-investigation, code-review, codex, design-principles, humanize-text, kill-dev-process, playwright-cli, backlog-api） |
| **プロジェクト固有**（各プロジェクトで管理） | プロジェクト独自スキル、プロジェクト固有の settings.json, .mcp.json カスタマイズ |

### デプロイ手順

担当者は1名。本リポジトリの更新とプロジェクトへの反映を一貫して行います。

1. **本リポジトリを更新** — `simount/claude-code-settings` を変更（`nokonoko1203/claude-code-settings` からの upstream マージ、または simount 固有の改善）
2. **共通ファイルをプロジェクトに反映** — 各プロジェクトリポの `.claude/` に共通ファイルをコピー。agents, hooks, 共通 skills は上書き。`settings.json` と `.mcp.json` はプロジェクト固有カスタマイズがあるため手動マージ
3. **プロジェクトリポにコミット** — チームは `git pull` で更新を受け取る

```bash
# 例: プロジェクトリポに共通ファイルを同期
SOURCE="/path/to/claude-code-settings"
TARGET="/path/to/project-repo/.claude"

# エージェント（全上書き）
cp -r "$SOURCE/agents/" "$TARGET/agents/"

# フック（全上書き）
cp -r "$SOURCE/hooks/" "$TARGET/hooks/"

# 共通スキル（名前指定で上書き、プロジェクト固有スキルは触らない）
for skill in bug-investigation code-review codex design-principles humanize-text kill-dev-process backlog-api; do
  mkdir -p "$TARGET/skills/$skill"
  cp -r "$SOURCE/skills/$skill/" "$TARGET/skills/$skill/"
done
cp -r "$SOURCE/skills/playwright-cli/" "$TARGET/skills/playwright-cli/"

# settings.json, .mcp.json — 手動マージ（プロジェクト固有カスタマイズあり）
echo "settings.json と .mcp.json は手動でマージしてください。"
```

### 本家（nokonoko1203）のマージ

simount 独自のカスタマイズ内容を確認: [GitHub で差分を表示](https://github.com/simount/claude-code-settings/compare/nokonoko1203:main...simount:main)

```bash
# 初回セットアップ（1回のみ）
git remote add upstream https://github.com/nokonoko1203/claude-code-settings.git

# upstream の変更を取り込み
git fetch upstream
git merge upstream/main --no-edit

# simount 独自の変更をローカルで確認
git diff upstream/main..main
git log upstream/main..main --oneline
```

> **注意:** `agents/backend-implementation-engineer.md` と `agents/frontend-implementation-engineer.md` は大幅に再構成されています（フレームワーク非依存化）。upstream マージ時にはこれらのファイルで手動コンフリクト解消が必要です。その他のファイルは軽微なコンフリクトで済むはずです。

### ユーザーレベル設定（`~/.claude/`）

ユーザーレベル設定（個人の `~/.claude/CLAUDE.md`, `~/.claude/settings.json`）はこのデプロイワークフローの**対象外**です。各開発者が自身のユーザーレベル設定を独自に管理します。個人のセットアップには上記のクイックインストールを利用できます。

## 参考リンク

- [Claude Code 概要](https://docs.anthropic.com/en/docs/claude-code)
- [Model Context Protocol (MCP)](https://docs.anthropic.com/en/docs/mcp)
- [OpenAI Codex](https://openai.com/codex)
- [textlint](https://textlint.github.io/)
- [CCManager](https://github.com/kbwo/ccmanager)
- [Context7](https://context7.com/)
- [Playwright CLI](https://www.npmjs.com/package/@playwright/cli)

## ライセンス

このプロジェクトは MIT ライセンスの下でリリースされています。
