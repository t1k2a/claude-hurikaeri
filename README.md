# Claude Standup（朝会・夕会アシスタント）

> **English summary:** A Claude Code skill that auto-collects your GitHub activity (commits, diffs, PRs) and runs daily standup meetings (morning planning + evening retrospective) as a scrum master. Supports `/standup morning` and `/standup evening` commands.
>
> Compatible with: Claude Code, OpenAI Codex CLI, Gemini CLI

[![Claude Code Skill](https://img.shields.io/badge/Claude%20Code-Skill-blue?logo=anthropic)](https://github.com/t1k2a/claude-hurikaeri)
[![skillsmp](https://img.shields.io/badge/skillsmp-Listed-green)](https://skillsmp.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

GitHub の作業状況を自動収集し、毎日の朝会・夕会を Claude と行うための Claude Code スキルです。

## 概要

GitHub リポジトリから以下の情報を自動収集し、スクラムマスターとして朝会・夕会を進めます：
- コミット履歴と変更詳細
- 未コミットの差分
- Pull Request の状態（オープン、マージ済み、レビュー待ち）

## インストール

### 前提条件

| ツール | 必須？ | OS 別インストール |
|--------|--------|------------------|
| Git 2.30+ | ✅ 必須 | macOS: `brew install git` / Ubuntu・WSL: `sudo apt install git` |
| GitHub CLI (`gh`) | ⭕️ オプション | macOS: `brew install gh` / Ubuntu・WSL: [公式手順](https://github.com/cli/cli/blob/trunk/docs/install_linux.md) |
| Bash 4.0+ | ✅ 必須 | macOS: `brew install bash` / Ubuntu・WSL: `sudo apt install bash` |
| curl | ✅ 必須（Webhook使用時） | macOS: 標準搭載 / Ubuntu・WSL: `sudo apt install curl` |

> **WSL ユーザーへ:** 文字化けが発生する場合は `.bashrc` に `export LANG=ja_JP.UTF-8` を追加してください。

### インストール手順

```bash
# 1. リポジトリをクローン
git clone https://github.com/t1k2a/claude-hurikaeri.git

# 2a. 個人用（全プロジェクトで使える）
mkdir -p ~/.claude/skills/
cp -r claude-hurikaeri/skills/standup ~/.claude/skills/

# 2b. または、プロジェクト用（特定プロジェクトのみ）
mkdir -p <your-project>/.claude/skills/
cp -r claude-hurikaeri/skills/standup <your-project>/.claude/skills/

# 3. 動作確認
bash -n ~/.claude/skills/standup/chatwork-notify.sh && echo "インストール成功"
```

### Webhook 通知の設定

通知を送信する場合、事前に環境変数を設定してください：

```bash
# Slack / Discord
export STANDUP_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# Chatwork（--notify chatwork オプション使用時）
export STANDUP_CHATWORK_TOKEN="your_api_token"
export STANDUP_CHATWORK_ROOM_ID="123456"

# Microsoft Teams（--notify teams オプション使用時）
export STANDUP_TEAMS_WEBHOOK_URL="https://prod-XX.westus.logic.azure.com/..."

# 永続化（.bashrc / .zshrc に追加）
echo 'export STANDUP_WEBHOOK_URL="..."' >> ~/.bashrc
```

## 使い方

Claude Code で以下のように呼び出します：

```bash
# 朝会（過去24時間の情報を収集）
/standup morning

# 夕会（過去10時間の情報を収集）
/standup evening

# 時間を指定
/standup morning 48

# 自然言語でもOK
「朝会を始めましょう」
「今日の振り返りをしたい」
```

### オプション

| オプション | 説明 |
|-----------|------|
| `--save` | レポートを `~/.standup-history/` に保存 |
| `--search <keyword>` | 過去の履歴からキーワード検索 |
| `--summary weekly\|monthly` | 週次・月次サマリーを表示 |
| `--export html` | HTML ファイルとしてエクスポート |
| `--notify` | Slack/Discord Webhook に送信 |
| `--notify chatwork` | Chatwork API v2 でルームに送信 |
| `--template <path>` | カスタムテンプレートを使用 |

### 前提条件

| ツール | 必須？ | 用途 |
|--------|--------|------|
| Git | ✅ 必須 | コミット履歴・差分取得 |
| GitHub CLI (`gh`) | ⭕️ オプション | PR・Issue 取得（`brew install gh` → `gh auth login`） |

## スキルの更新

```bash
cd claude-hurikaeri
git pull
cp -r skills/standup ~/.claude/skills/standup
```

## Chatwork 連携

Chatwork へのスタンドアップ通知を設定するには、以下の環境変数を設定してください。

```bash
# Chatwork API トークン（Chatwork の「サービス連携」→「API トークン」で取得）
export STANDUP_CHATWORK_TOKEN="your_api_token"

# 送信先ルーム ID（URL の #!rid の後の数字）
export STANDUP_CHATWORK_ROOM_ID="123456"
```

設定後、`--notify chatwork` オプションで通知できます：

```bash
/standup evening --notify chatwork
```

スクリプトを直接呼び出すこともできます：

```bash
skills/standup/chatwork-notify.sh "レポートテキスト"
```

## セキュリティ上の注意

Webhook URL を使用する際は環境変数で設定してください：

```bash
export STANDUP_WEBHOOK_URL="https://hooks.slack.com/services/..."
```

設定ファイル `.standup-config.json` を使う場合は必ず `.gitignore` に追加してください。

## よくある質問

**Q: プライベートリポジトリでも使える？**
A: はい。`gh auth login` で認証済みであれば、プライベートリポジトリの PR/Issue も取得できます。

**Q: どのリポジトリでも使える？**
A: Git リポジトリであれば使えます。GitHub 連携機能（PR、Issue）は GitHub リポジトリでのみ動作します。

**Q: cron で自動実行できる？**
A: はい。`cron-standup.sh` を使用してください。cron は環境変数を引き継がないため、スクリプト内で設定する必要があります：
```bash
# crontab -e に追加する例（平日 9:00 に朝会レポートを送信）
STANDUP_WEBHOOK_URL="https://hooks.slack.com/services/..."
0 9 * * 1-5 bash ~/.claude/skills/standup/cron-standup.sh
```

**Q: Webhook が届かない**
A: 以下を確認してください：
1. `echo $STANDUP_WEBHOOK_URL` で URL が設定されているか確認
2. `curl -s -o /dev/null -w "%{http_code}" -X POST "$STANDUP_WEBHOOK_URL" -d '{"text":"test"}'` で HTTP 200 が返るか確認
3. ファイアウォール・プロキシ設定を確認

**Q: WSL で文字化けする**
A: `.bashrc` に以下を追加してください：
```bash
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8
```

**Q: チーム複数人で使うには？**
A: `team-summary.sh` を使用してください：
```bash
bash ~/.claude/skills/standup/team-summary.sh \
  /path/to/member1-repo \
  /path/to/member2-repo
```

詳細は [CONTRIBUTING.md](./CONTRIBUTING.md) を参照してください。

## Custom Setup / カスタム構築のご相談

Claude Code エージェントチームの自社導入・カスタム構築を承っています。

- GitHub Discussions でお気軽にご相談ください → [Discussions を開く](https://github.com/t1k2a/claude-hurikaeri/discussions)
- 対応内容: Agent Team のセットアップ、カスタムエージェント開発、運用保守

> **For English speakers:** We offer consulting for custom Claude Code agent team setup. Open a Discussion or reach out via GitHub.

## ライセンス

MIT
