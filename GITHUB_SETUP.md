# GitHub セットアップガイド

スキルマーケットプレイスへの公開に必要な GitHub の設定手順です。

## 📋 GitHub Topics の設定

Topics を設定すると、他の開発者がスキルを見つけやすくなります。

### 方法1: Web UI から設定（推奨・簡単）

1. **リポジトリページを開く**
   ```
   https://github.com/t1k2a/claude-hurikaeri
   ```

2. **About セクションの設定を開く**
   - リポジトリ名の下にある「About」セクションを探す
   - 右側の ⚙️（歯車アイコン）をクリック

3. **Topics を追加**
   - 「Topics」フィールドに以下を入力:
     ```
     claude-code
     claude-code-skill
     standup
     scrum
     productivity
     github
     agile
     daily-standup
     automation
     workflow
     ```
   - または、1つずつ入力してEnterで確定

4. **Save changes をクリック**

### 方法2: GitHub CLI から設定（コマンドライン）

スクリプトを用意したので、以下を実行するだけです:

```bash
./setup-github-topics.sh
```

または手動で:

```bash
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  repos/t1k2a/claude-hurikaeri/topics \
  -f names='["claude-code","claude-code-skill","standup","scrum","productivity","github","agile","daily-standup","automation","workflow"]'
```

## 🏷️ Release の作成

### 方法1: Web UI から作成

1. **Releases ページを開く**
   ```
   https://github.com/t1k2a/claude-hurikaeri/releases/new
   ```

2. **タグを作成**
   - Tag: `v1.0.0`
   - Target: `main`

3. **リリース情報を入力**
   - Release title: `v1.0.0 - Initial Release`
   - Description:
     ```markdown
     ## 🎉 初回リリース

     GitHub の作業状況を自動収集し、Claude Code と朝会・夕会を行うスキルです。

     ### 機能

     - 📝 コミット履歴、差分、PR情報の自動収集
     - 🗣️ スクラムマスターとして対話的に進行
     - ⏰ 朝会（morning）・夕会（evening）モード
     - 🔧 時間指定可能

     ### インストール

     ```bash
     # Claude Code で以下のコマンドを実行
     /plugin install claude-hurikaeri

     # または手動インストール
     mkdir -p ~/.claude/skills/
     cp -r skills/standup ~/.claude/skills/
     ```

     ### 使い方

     ```bash
     # 朝会
     /standup morning

     # 夕会
     /standup evening

     # 時間指定
     /standup morning 48
     ```

     ### 必要なツール

     - Git（必須）
     - GitHub CLI `gh`（オプション・PR情報取得用）

     ---

     🤖 Generated with Claude Code
     ```

4. **Publish release をクリック**

### 方法2: GitHub CLI から作成

```bash
# タグを作成してプッシュ
git tag -a v1.0.0 -m "Initial release for skill marketplace"
git push origin v1.0.0

# GitHub Release を作成
gh release create v1.0.0 \
  --title "v1.0.0 - Initial Release" \
  --notes "## 🎉 初回リリース

GitHub の作業状況を自動収集し、Claude Code と朝会・夕会を行うスキルです。

### 機能

- 📝 コミット履歴、差分、PR情報の自動収集
- 🗣️ スクラムマスターとして対話的に進行
- ⏰ 朝会（morning）・夕会（evening）モード
- 🔧 時間指定可能

### インストール

\`\`\`bash
# Claude Code で以下のコマンドを実行
/plugin install claude-hurikaeri

# または手動インストール
mkdir -p ~/.claude/skills/
cp -r skills/standup ~/.claude/skills/
\`\`\`

### 使い方

\`\`\`bash
# 朝会
/standup morning

# 夕会
/standup evening

# 時間指定
/standup morning 48
\`\`\`

### 必要なツール

- Git（必須）
- GitHub CLI \`gh\`（オプション・PR情報取得用）

---

🤖 Generated with Claude Code"
```

## 📝 リポジトリの説明を更新

### Web UI から

1. **About セクションの設定を開く**（Topics と同じ画面）

2. **Description を入力**
   ```
   GitHub の作業状況を自動収集し、Claude Code と朝会・夕会を行うスキル
   ```

3. **Website を入力**（オプション）
   ```
   https://github.com/t1k2a/claude-hurikaeri#readme
   ```

4. **Save changes**

### GitHub CLI から

```bash
gh repo edit t1k2a/claude-hurikaeri \
  --description "GitHub の作業状況を自動収集し、Claude Code と朝会・夕会を行うスキル" \
  --homepage "https://github.com/t1k2a/claude-hurikaeri#readme"
```

## 🔍 設定の確認

すべての設定が完了したら、以下で確認:

```bash
# Topics を確認
gh api repos/t1k2a/claude-hurikaeri/topics | jq '.names'

# リポジトリ情報を確認
gh repo view t1k2a/claude-hurikaeri
```

または Web で確認:
```
https://github.com/t1k2a/claude-hurikaeri
```

## ✅ チェックリスト

設定完了後、以下を確認してください:

- [ ] Topics が設定されている（特に `claude-code-skill` が重要）
- [ ] Description が設定されている
- [ ] Release v1.0.0 が作成されている
- [ ] README が充実している
- [ ] LICENSE ファイルがある

すべて完了したら、スキルマーケットプレイスに公開準備完了です！🎉

## 🚀 次のステップ

1. **Claude Code コミュニティで共有**
   - Reddit, Discord, Twitter などで告知

2. **フィードバックを収集**
   - GitHub Issues でユーザーフィードバックを受け取る

3. **継続的な改善**
   - バグ修正
   - 機能追加
   - ドキュメント改善
