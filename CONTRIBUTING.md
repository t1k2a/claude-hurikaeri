# Contributing to claude-hurikaeri

このプロジェクトへの貢献に興味を持っていただきありがとうございます。本ドキュメントでは、環境セットアップ・変更の提出・プロジェクト構造について説明します。

---

## 目次

1. [プロジェクト概要](#プロジェクト概要)
2. [前提条件](#前提条件)
3. [インストール](#インストール)
4. [ディレクトリ構造](#ディレクトリ構造)
5. [開発ワークフロー](#開発ワークフロー)
6. [変更の提出](#変更の提出)
7. [コーディングガイドライン](#コーディングガイドライン)
8. [SKILL.md の記述ルール](#skillmd-の記述ルール)
9. [テスト方法](#テスト方法)
10. [Issue ラベル](#issue-ラベル)
11. [FAQ](#faq)

---

## プロジェクト概要

claude-hurikaeri は、GitHub の作業状況（コミット・差分・PR）を自動収集し、朝会・夕会をスクラムマスターとして進行する Claude Code スキルです。

また、SKILL.md ベースのエージェント（CEO / Dev / Ops Division）が Issue の管理・開発サイクルを自律的に運営する自律型マルチエージェントシステムも含まれています。

---

## 前提条件

### 必須ツール

| ツール | バージョン | 用途 |
|--------|-----------|------|
| Git | 2.30+ | バージョン管理 |
| GitHub CLI (`gh`) | 2.0+ | PR・Issue 管理 |
| Bash | 4.0+ | スキルスクリプト実行 |
| Claude Code | 最新版 | SKILL.md エージェント実行 |
| curl | 7.0+ | Webhook 送信 |

### OS 別インストール手順

#### macOS

```bash
# Homebrew 経由
brew install git gh bash curl

# GitHub CLI 認証
gh auth login
```

#### Ubuntu / WSL (Windows Subsystem for Linux)

```bash
# 基本ツール
sudo apt update && sudo apt install -y git curl bash

# GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh

# GitHub CLI 認証
gh auth login
```

#### WSL 固有の注意事項

- Bash バージョンを確認: `bash --version`（4.0 未満の場合は `sudo apt install bash` で更新）
- 文字化けが発生する場合は `export LANG=ja_JP.UTF-8` を `.bashrc` に追加

---

## インストール

### 個人用（全プロジェクトで使える）

```bash
git clone https://github.com/t1k2a/claude-hurikaeri.git
mkdir -p ~/.claude/skills/
cp -r claude-hurikaeri/skills/standup ~/.claude/skills/
```

### プロジェクト固有（特定プロジェクトのみ）

```bash
git clone https://github.com/t1k2a/claude-hurikaeri.git
mkdir -p <your-project>/.claude/skills/
cp -r claude-hurikaeri/skills/standup <your-project>/.claude/skills/
```

### インストール確認

```bash
# スキルが存在するか確認
ls ~/.claude/skills/standup/

# シンタックスチェック
bash -n ~/.claude/skills/standup/chatwork-notify.sh && echo "OK"
bash -n ~/.claude/skills/standup/team-summary.sh && echo "OK"
```

期待される結果: すべてのチェックで `OK` が表示される

### Webhook URL の設定

Slack / Discord の場合:

```bash
export STANDUP_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

Chatwork の場合:

```bash
export STANDUP_CHATWORK_TOKEN="your_api_token"
export STANDUP_CHATWORK_ROOM_ID="123456"
```

LINE WORKS の場合:

```bash
export STANDUP_LINEWORKS_WEBHOOK_URL="https://hooks.worksmobile.com/..."
```

これらの環境変数を `.bashrc` / `.zshrc` に追加しておくと、毎回設定する手間が省けます。

---

## ディレクトリ構造

```
claude-hurikaeri/
├── skills/
│   └── standup/
│       ├── SKILL.md              # スキルのエントリポイント（Claude Code が読む）
│       ├── chatwork-notify.sh    # Chatwork 通知スクリプト
│       ├── team-summary.sh       # チームサマリー生成スクリプト
│       └── default-template.md  # デフォルトレポートテンプレート
├── docs/                         # 各種設計ドキュメント
├── CONTRIBUTING.md               # 本ドキュメント
├── README.md                     # ユーザー向けドキュメント
└── LICENSE
```

---

## 開発ワークフロー

### 1. Issue の確認

作業前に既存の Issue を確認し、重複を避けてください。

```bash
gh issue list --state open
```

### 2. ブランチ作成

**ブランチ命名規則:** `feature/issue-<Issue番号>-<簡潔な説明>`

```bash
# 例
git checkout -b feature/issue-60-japanese-template
git checkout -b fix/issue-38-error-handling
git checkout -b docs/issue-56-contributing-guide
```

| プレフィックス | 用途 |
|--------------|------|
| `feature/` | 新機能追加 |
| `fix/` | バグ修正 |
| `docs/` | ドキュメント更新 |
| `chore/` | リファクタリング・設定変更 |

### 3. 実装・テスト

変更を実装し、[テスト方法](#テスト方法) に従ってテストを実行してください。

### 4. コミット

```bash
git add <変更ファイル>
git commit -m "feat: <変更内容の簡潔な説明> #<Issue番号>"
```

**コミットメッセージ規則:**

| プレフィックス | 用途 |
|--------------|------|
| `feat:` | 新機能 |
| `fix:` | バグ修正 |
| `docs:` | ドキュメント |
| `chore:` | その他（リファクタリング等） |
| `ci:` | CI/CD 設定 |

---

## 変更の提出

### PR の作成

```bash
git push origin feature/issue-XX-your-feature
gh pr create --title "feat: <タイトル> #<Issue番号>" --body "..."
```

### PR チェックリスト

PR を作成する前に以下を確認してください：

- [ ] `bash -n` シンタックスチェックがすべて通過する
- [ ] 環境変数未設定時に分かりやすいエラーメッセージが表示される
- [ ] `SKILL.md` が新機能・オプションに合わせて更新されている
- [ ] `README.md` にユーザー向けの説明が追記されている
- [ ] 対応する Issue 番号が PR 本文に `Closes #XX` 形式で記載されている

### PR 本文テンプレート

```markdown
## 概要
<何を実装したかの1〜2文>

## 変更内容
- 作成: `path/to/file.sh` — <説明>
- 変更: `path/to/other.md` — <説明>

## テスト
- [ ] `bash -n` シンタックスチェック PASS
- [ ] 環境変数未設定時のエラーメッセージ確認

Closes #XX
```

---

## コーディングガイドライン

### シェルスクリプト

```bash
#!/usr/bin/env bash
# スクリプトの説明
#
# 使用方法:
#   REQUIRED_VAR="value" ./script.sh "引数"
#
# 環境変数:
#   REQUIRED_VAR — 説明（必須）
#   OPTIONAL_VAR — 説明（オプション、デフォルト: 値）

set -euo pipefail
```

- **必ず `set -euo pipefail` を先頭に置く**
- **ファイル名は `kebab-case`**: `chatwork-notify.sh`, `team-summary.sh`
- **変数は大文字 + アンダースコア**: `CHATWORK_TOKEN`, `RETRY_COUNT`
- **環境変数のプレフィックスは `STANDUP_`**: `STANDUP_WEBHOOK_URL`
- **エラーは `>&2` で stderr に出力**:
  ```bash
  echo "エラー: 環境変数 STANDUP_CHATWORK_TOKEN が設定されていません。" >&2
  exit 1
  ```
- **リトライ処理は最大3回**: Webhook 送信など外部通信はリトライ対応を推奨
- **テンポラリファイルは `/tmp/` 以下**: クリーンアップも実装する

### Markdown / ドキュメント

- 見出しは `#` / `##` / `###` の3階層まで
- コードブロックには言語を指定: ` ```bash `, ` ```json `
- 日本語と英語の混在は最小限に（ユーザー向けは日本語優先）

---

## SKILL.md の記述ルール

### frontmatter（必須）

```yaml
---
name: skill-name
description: >
  1行の説明。Claude Code がスキルを認識するために使う。
argument-hint: "[morning|evening] [options]"
---
```

- `name`: kebab-case で一意の名前
- `description`: Claude Code が `/` コマンドの候補表示に使う。簡潔に
- `argument-hint`: ユーザーへのヒント表示に使う

### 本文構造

```markdown
# スキル名

## Step 1: 〇〇する

説明テキスト

​```bash
# コマンド例
command --option
​```

## Step 2: 〇〇する
...
```

- 各 Step は `## Step N:` で始める
- コマンドブロックにはコメントで説明を付ける
- `$ARGUMENTS` プレースホルダーで引数を参照する

### 新しいオプションを追加するとき

1. `SKILL.md` の frontmatter `argument-hint` を更新
2. 該当する Step に処理フローを追加
3. ドキュメントセクション（末尾付近）に使い方を追記

---

## テスト方法

### シンタックスチェック（必須）

```bash
# すべてのシェルスクリプトを確認
find skills/ -name "*.sh" -exec bash -n {} \; && echo "All OK"
```

### 環境変数未設定テスト

```bash
# 例: Chatwork 通知スクリプト
STANDUP_CHATWORK_TOKEN="" bash skills/standup/chatwork-notify.sh "test"
# 期待: エラーメッセージが表示されて終了コード 1
```

### 動作確認

```bash
# スタンドアップ実行（実際のリポジトリで確認）
/standup morning /path/to/your-repo

# 新機能の動作確認は README.md の「テスト方法」セクションを参照
```

---

## Issue ラベル

| ラベル | 説明 |
|--------|------|
| `enhancement` | 新機能・改善要望 |
| `bug` | バグ報告 |
| `documentation` | ドキュメント関連 |
| `agent-task` | Agent Team が自動起票したタスク |
| `management-request` | 経営 Agent からの要望 |
| `needs-human` | 人間の判断が必要 |
| `research` | 調査・分析タスク |

---

## FAQ

**Q: cron で動かない**

A: cron は環境変数を引き継がないため、スクリプト内で明示的に設定してください：
```bash
# crontab -e に追加する例
STANDUP_WEBHOOK_URL="https://hooks.slack.com/..."
0 9 * * 1-5 bash ~/.claude/skills/standup/cron-standup.sh
```

**Q: Webhook が届かない**

A: 以下を確認してください：
1. `curl -s -o /dev/null -w "%{http_code}" -X POST "$STANDUP_WEBHOOK_URL" -d '{"text":"test"}'` で HTTP 200 が返るか
2. Webhook URL が正しいか（Slack は `https://hooks.slack.com/services/` から始まる）
3. ネットワーク接続に問題がないか

**Q: WSL で文字化けする**

A: `.bashrc` に以下を追加してください：
```bash
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8
```

**Q: チーム複数人で使うには？**

A: `skills/standup/team-summary.sh` を使用してください。各メンバーのスタンドアップ回答を収集・集計してチームサマリーを生成できます：
```bash
bash skills/standup/team-summary.sh \
  /path/to/member1-repo \
  /path/to/member2-repo
```

**Q: プライベートリポジトリでも使える？**

A: はい。`gh auth login` で認証済みであれば、プライベートリポジトリの PR・Issue も取得できます。

**Q: どのリポジトリでも使える？**

A: Git リポジトリであれば使えます。GitHub 連携機能（PR、Issue）は GitHub リポジトリでのみ動作します。

---

## サポート・スポンサーシップ

### GitHub Sponsors

GitHub Sponsors でプロジェクトを支援できます（リンク準備中）。
スポンサーには Issue への優先対応・新機能の先行アクセスが含まれます。

### 商用サポート契約

保証された対応時間やカスタムスキル開発が必要なチーム向けにサポート契約を提供しています。

**お問い合わせ:** `support-inquiry` ラベルで Issue を開くか、リポジトリプロフィールのメールアドレスへご連絡ください。

詳細は [PRICING.md](./PRICING.md) を参照してください。

### Skills Marketplace

claude-hurikaeri のスキルは Claude Code スキルマーケットプレイスで公開しています：
- [skillsmp.com](https://skillsmp.com) — 登録済み
- [SkillHQ](https://skillhq.dev/) — 登録準備中
