# Claude Standup（朝会・夕会アシスタント）

GitHub の作業状況を自動収集し、毎日の朝会・夕会を Claude と行うためのツールです。
Claude Code スキルまたは MCP サーバーとして利用できます。

## 概要

GitHub リポジトリから以下の情報を自動収集し、スクラムマスターとして朝会・夕会を進めます：
- コミット履歴と変更詳細
- 未コミットの差分
- Pull Request の状態（オープン、マージ済み、レビュー待ち）

## Claude Code スキルとしての使い方（推奨）

MCP サーバーのセットアップ不要で、Claude Code から直接使えます。

### インストール

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

### 使い方

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

### 前提条件

| ツール | 必須？ | 用途 | インストール |
|--------|--------|------|-------------|
| Git | ✅ 必須 | コミット履歴・差分取得 | 通常インストール済み |
| GitHub CLI (`gh`) | ⭕️ オプション | PR・Issue 取得 | `brew install gh` → `gh auth login` |

> **注意**: `gh` CLI がインストールされていない場合でも、コミット履歴や差分などの基本的な Git 情報は取得できます。PR情報のみ表示されません。

---

## MCP サーバーとしての使い方

MCP サーバーとしても利用できます。Claude Desktop との連携が必要な場合はこちらをお使いください。

### 提供される機能

- **Tools**: `collect_standup_info` - リポジトリから朝会・夕会用の情報を収集
- **Resources**: `standup://current` - 現在のディレクトリのスタンドアップ情報
- **Prompts**: `morning-standup`（朝会）/ `evening-standup`（夕会）

### 1. 前提条件

以下のツールがインストールされている必要があります：

| ツール | 必須？ | 用途 | インストール |
|--------|--------|------|-------------|
| Node.js | ✅ 必須 | MCP サーバー実行 | [nodejs.org](https://nodejs.org/) |
| Git | ✅ 必須 | コミット履歴・差分取得 | 通常インストール済み |
| GitHub CLI (`gh`) | ⭕️ オプション | PR・Issue 取得 | `brew install gh` → `gh auth login` |

> **注意**: `gh` CLI がない場合でも基本機能は動作します。PR情報のみ取得できません。

### 2. GitHub CLI の認証

```bash
gh auth login
```

### 3. MCP サーバーのインストール

```bash
# npmからインストール（公開後）
npm install -g claude-hurikaeri-mcp

# または、このリポジトリから直接
git clone https://github.com/t1k2a/claude-hurikaeri.git
cd claude-hurikaeri
npm install
npm run build
npm link
```

### 4. Claude Desktop の設定

Claude Desktop の設定ファイル（`~/Library/Application Support/Claude/claude_desktop_config.json`）に以下を追加：

```json
{
  "mcpServers": {
    "claude-standup": {
      "command": "node",
      "args": ["/path/to/claude-hurikaeri/build/index.js"]
    }
  }
}
```

または、グローバルインストールした場合：

```json
{
  "mcpServers": {
    "claude-standup": {
      "command": "claude-hurikaeri-mcp"
    }
  }
}
```

### 5. Claude Desktop を再起動

設定を反映させるため、Claude Desktop を再起動してください。

## MCP を使った朝会・夕会の進め方

### 方法1: Prompts を使う（推奨）

Claude Desktop で以下のように入力：

**朝会：**
```
Use morning-standup prompt with repo_path: ~/projects/my-app
```

**夕会：**
```
Use evening-standup prompt with repo_path: ~/projects/my-app and work_hours: 10
```

### 方法2: Tools を使う

Claude Desktop で以下のように依頼：

```
Collect standup info from ~/projects/my-app for the last 24 hours
```

Claude が `collect_standup_info` ツールを自動的に呼び出します。

### 方法3: Resources を使う

現在のディレクトリのスタンドアップ情報を取得：

```
Show me the standup://current resource
```

---

## スタンドアロン版（シェルスクリプト）の使い方

MCP を使わずに、従来のシェルスクリプトでも利用できます。

### 1. スクリプトの配置

```bash
# ~/bin ディレクトリを作成（なければ）
mkdir -p ~/bin

# スクリプトを standup という名前でコピー
cp collect.sh ~/bin/standup
chmod +x ~/bin/standup

# PATH に追加（~/.zshrc または ~/.bashrc に書く）
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 2. 使い方

```bash
# リポジトリの情報を収集
standup ~/projects/my-app

# 期間を変えたい場合
SINCE_HOURS=48 standup ~/projects/my-app
```

→ `~/standup/my-app_2026-02-09.md` のようなファイルが生成され、自動でクリップボードにコピーされます。

### 3. Claude で使う

1. claude.ai のプロジェクトを開く
2. クリップボードの内容をペースト（Cmd+V）

---

## Agent Team スキルのインストール

```bash
mkdir -p ~/.claude/skills/agent-team/agents
cp -r skills/agent-team/. ~/.claude/skills/agent-team/
```

### 使い方

```bash
# セッション開始時に起動（セッション中のみ有効）
/agent-team start

# 停止
/agent-team stop

# 一時停止（例: 24時間）
/agent-team pause 24h

# 状態確認
/agent-team status
```

---

## 複数リポジトリの場合

### MCP 版

複数のリポジトリの情報を順番に取得：

```
Collect standup info from:
1. ~/projects/repo-a
2. ~/projects/repo-b
```

### スタンドアロン版

```bash
# それぞれ実行
standup ~/projects/repo-a
standup ~/projects/repo-b

# まとめて1つのファイルにする
COMBINED="/tmp/all_standup.md"
> "$COMBINED"
for repo in ~/projects/repo-a ~/projects/repo-b; do
  standup "$repo"
  cat ~/standup/"$(basename $repo)"_"$(date '+%Y-%m-%d')".md >> "$COMBINED"
  echo -e "\n\n" >> "$COMBINED"
done
cat "$COMBINED" | pbcopy
```

## カスタマイズ例

### 出力先を変える
```bash
# デフォルトは ~/standup/
# 環境変数で変更可能
export STANDUP_DIR=~/Documents/standup
standup ~/projects/my-app
```

### 収集期間を変える
```bash
# 環境変数で指定
export SINCE_HOURS=48  # 2日分
```

### cron で自動収集（macOS）
```bash
# 毎朝 8:50 に自動実行
crontab -e
# 以下を追加:
50 8 * * 1-5 ~/bin/standup ~/projects/my-app
```

### Automator / ショートカットと組み合わせ
macOS の Automator やショートカットアプリで、スクリプト実行 → Claude を開くまでを自動化できます。

## よくある質問

**Q: MCP 版とスタンドアロン版の違いは？**
A: MCP 版は Claude Desktop と直接連携し、プロンプトやツールとして統合されます。スタンドアロン版はシェルスクリプトで、claude.ai でも使えます。

**Q: MCP サーバーが動作しない場合は？**
A: 以下を確認してください：
- GitHub CLI (`gh`) が認証済みか: `gh auth status`
- Node.js のバージョンが 18 以上か: `node --version`
- Claude Desktop を再起動したか

**Q: プライベートリポジトリでも使える？**
A: はい。`gh` CLI が認証済みなら、プライベートリポジトリの PR/Issue も取得できます。

**Q: どのリポジトリでも使える？**
A: Git リポジトリであれば使えます。GitHub 連携機能（PR、Issue）は GitHub リポジトリでのみ動作します。

## 開発者向け

### ビルド

```bash
npm run build
```

### ウォッチモード

```bash
npm run watch
```

### ローカルテスト

```bash
# ビルド後
node build/index.js
```

## ライセンス

MIT

## 貢献

Issue や Pull Request をお待ちしています！
