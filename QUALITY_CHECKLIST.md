# 品質チェックリスト

スキルマーケットプレイスに公開する前の品質確認項目です。

## ✅ 公式仕様への準拠

### plugin.json の検証

- [x] **公式スキーマに準拠**
  - [x] 必須フィールド: `name`
  - [x] 推奨フィールド: `version`, `description`, `author`, `repository`, `homepage`, `license`, `keywords`
  - [x] 非公式フィールドを削除: `displayName`, `category`, `requirements`（公式スキーマに存在しない）

- [x] **JSON 構文が正しい**
  ```bash
  python3 -m json.tool .claude-plugin/plugin.json
  ```

### ディレクトリ構造

公式ドキュメント: https://code.claude.com/docs/en/plugins-reference

- [x] **正しい配置**
  - [x] `.claude-plugin/plugin.json` - メタデータのみ
  - [x] `skills/` - スキル定義（ルートレベル）
  - [x] `README.md` - プロジェクト説明（ルートレベル）
  - [x] `LICENSE` - ライセンスファイル

- [ ] **推奨ファイル**
  - [ ] `CHANGELOG.md` - 変更履歴
  - [ ] `.claude-plugin/README.md` - スキルの詳細説明

## 🧪 動作テスト

### ローカルテスト

1. **ビルド**
   ```bash
   npm run build
   # ✅ エラーなく完了すること
   ```

2. **スキルのインストール**
   ```bash
   mkdir -p ~/.claude/skills/test-standup
   cp -r skills/standup/* ~/.claude/skills/test-standup/
   ```

3. **Claude Code で動作確認**
   - [ ] `/standup morning` が実行できる
   - [ ] `/standup evening` が実行できる
   - [ ] 時間指定 `/standup morning 48` が動作する
   - [ ] 自然言語 「朝会を始めましょう」で起動する

4. **エラーケース**
   - [ ] Git リポジトリでない場所: 適切なエラーメッセージ
   - [ ] `gh` CLI なし: 警告を表示するが動作する
   - [ ] コミットがない場合: 「コミットなし」と表示

## 📝 ドキュメント品質

### README.md（プロジェクト）

- [x] **明確な説明**
  - [x] プロジェクトの目的
  - [x] 主な機能
  - [x] インストール方法
  - [x] 使い方（例付き）

- [x] **前提条件が明記**
  - [x] 必須ツール
  - [x] オプションツール
  - [x] インストール手順

### .claude-plugin/README.md（スキル説明）

- [x] **簡潔で分かりやすい**
  - [x] スキルの機能説明
  - [x] 使用例
  - [x] 収集される情報
  - [x] 朝会・夕会の流れ

### SKILL.md（実装）

- [ ] **明確な指示**
  - [ ] 引数の解釈方法
  - [ ] 実行手順
  - [ ] コミュニケーションスタイル

## 🔒 セキュリティ

- [x] **機密情報を含まない**
  - [x] API キーなし
  - [x] パスワードなし
  - [x] プライベート情報なし

- [x] **安全なコマンド実行**
  - [x] ユーザー入力の検証
  - [x] パス トラバーサル対策
  - [x] コマンドインジェクション対策

## 🎨 コード品質

### TypeScript（該当する場合）

- [x] **ビルドが通る**
  ```bash
  npm run build
  ```

- [ ] **型安全**
  - [x] 型定義が適切
  - [ ] any の乱用なし
  - [x] エラーハンドリング

### スキル実装

- [ ] **明確な指示**
  - [ ] ステップバイステップの手順
  - [ ] エラー処理の指示
  - [ ] フォールバック処理

## 📊 メタデータ品質

### package.json

- [x] **npm パッケージとして有効**
  - [x] 名前、バージョン、説明
  - [x] リポジトリURL
  - [x] キーワード
  - [x] ライセンス

### plugin.json

- [x] **適切なメタデータ**
  - [x] 分かりやすい説明
  - [x] 適切なキーワード（検索性）
  - [x] 作者情報
  - [x] リポジトリURL

## 🌐 互換性

- [ ] **プラットフォーム**
  - [ ] macOS で動作確認
  - [ ] Linux で動作確認
  - [ ] Windows（WSL）で動作確認

- [x] **Git リポジトリ**
  - [x] GitHub リポジトリ
  - [ ] GitLab（オプション）
  - [ ] Bitbucket（オプション）

## 📦 配布準備

### GitHub リポジトリ

- [x] **public リポジトリ**
- [ ] **README が充実**
- [ ] **Topics を設定**
  - [ ] `claude-code`
  - [ ] `claude-code-skill`
  - [ ] `standup`
  - [ ] `scrum`
  - [ ] `productivity`

### リリース

- [ ] **Git タグ**
  ```bash
  git tag -a v1.0.0 -m "Initial release"
  git push origin v1.0.0
  ```

- [ ] **GitHub Release**
  - [ ] リリースノート
  - [ ] スクリーンショット（推奨）
  - [ ] デモ動画（推奨）

## 🚀 マーケットプレイス申請

### 公式チャンネル

公式申請方法を確認：
- Claude Code 内の `/plugin` から Discover タブ
- または公式申請フォーム（存在する場合）

### コミュニティマーケットプレイス

- [ ] **GitHub Topics で公開**
  - タグを付けることで自動的に発見可能に
  - `claude-code-skill` タグは必須

- [ ] **SkillsMP など**
  - https://skillsmp.com/
  - サードパーティマーケットプレイスに登録（オプション）

## 📈 公開後のメンテナンス

- [ ] **Issue への対応**
- [ ] **プルリクエストのレビュー**
- [ ] **定期的なアップデート**
- [ ] **セキュリティ脆弱性の監視**

---

## ✅ 最終チェック

すべての項目をチェックしたら、公開準備完了です！

**推奨される公開フロー**:

1. ローカルでテスト
2. GitHub にプッシュ
3. GitHub Release を作成
4. GitHub Topics を設定
5. Claude Code コミュニティで共有
6. フィードバックを収集
7. 改善とアップデート

---

## 参考リンク

- [Claude Code Plugins Reference](https://code.claude.com/docs/en/plugins-reference)
- [Official Plugins Repository](https://github.com/anthropics/claude-plugins-official)
- [Agent Skills Specification](https://github.com/anthropics/skills)

Sources:
- [Extend Claude with skills - Claude Code Docs](https://code.claude.com/docs/en/skills)
- [Plugins reference - Claude Code Docs](https://code.claude.com/docs/en/plugins-reference)
- [GitHub - anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official)
