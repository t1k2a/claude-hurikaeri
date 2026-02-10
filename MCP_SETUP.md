# MCP サーバーのセットアップ手順

## 1. このリポジトリのビルド

```bash
cd /path/to/claude-hurikaeri
npm install
npm run build
```

## 2. Claude Desktop の設定

### macOS の場合

設定ファイルの場所:
```
~/Library/Application Support/Claude/claude_desktop_config.json
```

### Linux の場合

設定ファイルの場所:
```
~/.config/Claude/claude_desktop_config.json
```

### Windows の場合

設定ファイルの場所:
```
%APPDATA%\Claude\claude_desktop_config.json
```

## 3. 設定ファイルの編集

上記のファイルを開き、以下の内容を追加：

```json
{
  "mcpServers": {
    "claude-standup": {
      "command": "node",
      "args": [
        "/absolute/path/to/claude-hurikaeri/build/index.js"
      ]
    }
  }
}
```

**重要**: `/absolute/path/to/` の部分を実際のパスに置き換えてください。

例（macOS/Linux）:
```json
{
  "mcpServers": {
    "claude-standup": {
      "command": "node",
      "args": [
        "/Users/username/projects/claude-hurikaeri/build/index.js"
      ]
    }
  }
}
```

例（Windows）:
```json
{
  "mcpServers": {
    "claude-standup": {
      "command": "node",
      "args": [
        "C:\\Users\\username\\projects\\claude-hurikaeri\\build\\index.js"
      ]
    }
  }
}
```

## 4. Claude Desktop を再起動

設定を反映させるため、Claude Desktop を完全に終了して再起動してください。

## 5. 動作確認

Claude Desktop で以下のように入力して試してみてください：

### Prompts を使った朝会

```
Use morning-standup prompt with repo_path: /path/to/your/repo
```

### Prompts を使った夕会

```
Use evening-standup prompt with repo_path: /path/to/your/repo and work_hours: 10
```

### Tools を直接使う

```
Collect standup info from /path/to/your/repo for the last 24 hours
```

### Resources を使う

```
Show me the standup://current resource
```

（注: リソースは Claude Desktop が起動したディレクトリが基準になります）

## トラブルシューティング

### MCP サーバーが表示されない

1. Claude Desktop を完全に終了して再起動
2. 設定ファイルのパスが正しいか確認
3. JSON の構文が正しいか確認（カンマやブラケットなど）

### エラーが出る場合

1. `gh` CLI がインストールされているか: `gh --version`
2. `gh` が認証されているか: `gh auth status`
3. Git リポジトリのパスが正しいか確認
4. Node.js のバージョンが 18 以上か: `node --version`

### ログの確認

Claude Desktop のログを確認するには、アプリのメニューから「Help」→「Show Logs」を選択してください。

## グローバルインストール（オプション）

npm link を使ってグローバルにインストールすることもできます：

```bash
cd /path/to/claude-hurikaeri
npm link
```

その後、設定ファイルを以下のように簡略化できます：

```json
{
  "mcpServers": {
    "claude-standup": {
      "command": "claude-hurikaeri-mcp"
    }
  }
}
```

## npm 公開後のインストール（将来）

npm に公開した後は、以下のコマンドでインストールできます：

```bash
npm install -g claude-hurikaeri-mcp
```

設定ファイル:
```json
{
  "mcpServers": {
    "claude-standup": {
      "command": "claude-hurikaeri-mcp"
    }
  }
}
```
