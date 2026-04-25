# Claude Standup（朝会・夕会アシスタント）

GitHub の作業状況を自動収集し、毎日の朝会・夕会を Claude と行うための Claude Code スキルです。

## 概要

GitHub リポジトリから以下の情報を自動収集し、スクラムマスターとして朝会・夕会を進めます：
- コミット履歴と変更詳細
- 未コミットの差分
- Pull Request の状態（オープン、マージ済み、レビュー待ち）

## インストール

```bash
# リポジトリをクローン
git clone https://github.com/t1k2a/claude-hurikaeri.git

# 個人用（全プロジェクトで使える）
mkdir -p ~/.claude/skills/
cp -r claude-hurikaeri/skills/standup ~/.claude/skills/

# または、プロジェクト用（特定プロジェクトのみ）
mkdir -p <your-project>/.claude/skills/
cp -r claude-hurikaeri/skills/standup <your-project>/.claude/skills/
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

## セキュリティ上の注意

Webhook URL を使用する際は環境変数で設定してください：

```bash
export STANDUP_WEBHOOK_URL="https://hooks.slack.com/services/..."
```

設定ファイル `.standup-config.json` を使う場合は必ず `.gitignore` に追加してください。

## よくある質問

**Q: プライベートリポジトリでも使える？**
A: はい。`gh` CLI が認証済みなら、プライベートリポジトリの PR/Issue も取得できます。

**Q: どのリポジトリでも使える？**
A: Git リポジトリであれば使えます。GitHub 連携機能（PR、Issue）は GitHub リポジトリでのみ動作します。

## ライセンス

MIT
