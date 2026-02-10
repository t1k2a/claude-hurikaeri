# 🎙️ Claude Standup MCP Server

GitHub の作業状況を自動収集し、Claude の音声モードで毎日の朝会・夕会を行うための MCP サーバーです。

## 概要

このプロジェクトは、GitHub リポジトリから以下の情報を収集します：
- コミット履歴と変更詳細
- 未コミットの差分
- Pull Request の状態（オープン、マージ済み、レビュー待ち）

収集した情報を Claude に渡すことで、朝会・夕会を効率的に進められます。

## 提供される機能

### 🔧 Tools（ツール）
- **collect_standup_info** - リポジトリから朝会・夕会用の情報を収集

### 📦 Resources（リソース）
- **standup://current** - 現在のディレクトリのスタンドアップ情報

### 💬 Prompts（プロンプト）
- **morning-standup** - 朝会用のプロンプト（過去24時間の情報）
- **evening-standup** - 夕会用のプロンプト（今日の作業分）

## 必要なもの

| ツール | 用途 | インストール |
|--------|------|-------------|
| Git | コミット履歴・差分取得 | 通常インストール済み |
| GitHub CLI (`gh`) | PR・Issue 取得 | `brew install gh` |
| Claude アプリ | 音声対話 | iOS / Android / Desktop |

## MCP サーバーとしての使い方

### 1. 前提条件

以下のツールがインストールされている必要があります：

| ツール | 用途 | インストール |
|--------|------|-------------|
| Node.js | MCP サーバー実行 | [nodejs.org](https://nodejs.org/) |
| Git | コミット履歴・差分取得 | 通常インストール済み |
| GitHub CLI (`gh`) | PR・Issue 取得 | `brew install gh` |

### 2. GitHub CLI の認証

```bash
gh auth login
```

### 3. MCP サーバーのインストール

```bash
# npmからインストール（公開後）
npm install -g claude-hurikaeri-mcp

# または、このリポジトリから直接
git clone https://github.com/your-username/claude-hurikaeri.git
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

### 音声モードでの使い方

1. Claude Desktop で上記のいずれかの方法で情報を取得
2. 🎤 音声モードに切り替え（マイクアイコンをクリック）
3. 自然な会話で朝会・夕会を進める

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
3. 🎤 音声モードに切り替えて会話

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

## 音声モードの Tips

- **静かな環境**で使うと認識精度が上がる
- **短い文で話す**と Claude の応答が速い
- 「次」「続けて」などで会話を進められる
- 技術用語は認識されにくいこともあるので、固有名詞はチャットで補足するとよい
- 朝の通勤中に AirPods で使うのもおすすめ

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

**Q: 音声モードで使える？**
A: はい。Claude Desktop の音声モードと組み合わせて、自然な会話形式で朝会・夕会を進められます。

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
