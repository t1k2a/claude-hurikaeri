# スキルマーケットプレイス公開チェックリスト

このチェックリストを使って、スキルマーケットプレイスへの公開準備を確認してください。

## ✅ 必須項目

### ファイル構成

- [x] `.claude-plugin/plugin.json` - メタデータ
- [x] `.claude-plugin/README.md` - スキルの説明
- [x] `skills/standup/SKILL.md` - スキルの実装
- [x] `README.md` - プロジェクトの説明
- [x] `package.json` - npm パッケージ情報
- [x] `LICENSE` - ライセンスファイル

### plugin.json の内容

- [x] `name` - スキル名
- [x] `displayName` - 表示名（日本語 + 英語）
- [x] `description` - 詳細な説明
- [x] `version` - バージョン (1.0.0)
- [x] `author` - 作者情報
- [x] `repository` - GitHubリポジトリURL
- [x] `homepage` - ホームページURL
- [x] `license` - ライセンス (MIT)
- [x] `category` - カテゴリ (productivity)
- [x] `keywords` - キーワード
- [x] `requirements` - 依存ツール

### コード品質

- [x] TypeScript ビルドが通る (`npm run build`)
- [ ] スキルが正常に動作する（ローカルテスト）
- [ ] エラーハンドリングが適切
- [x] GitHub CLI がない場合も動作する

### ドキュメント

- [x] README.md に使い方が記載されている
- [x] 前提条件が明記されている
- [x] インストール手順が明確
- [x] 使用例が豊富

## 📸 推奨項目

### ビジュアル素材

- [ ] **スクリーンショット**: 実際の使用例（1〜3枚）
  - 朝会の実行例
  - 収集される情報の例
  - 会話の流れの例

- [ ] **デモ動画**: 短い動画（30秒〜1分）
  - `/standup morning` の実行
  - 朝会の進行
  - 結果の確認

- [ ] **アイコン/ロゴ**: スキルのアイコン画像
  - サイズ: 512x512px 推奨
  - 形式: PNG, SVG

### 追加ドキュメント

- [ ] **FAQ**: よくある質問と回答
- [ ] **トラブルシューティング**: よくある問題と解決方法
- [ ] **ユースケース**: 具体的な活用例

## 🚀 公開前の最終確認

### ローカルテスト

1. **ビルド**
   ```bash
   npm run build
   ```

2. **スキルのインストール**
   ```bash
   mkdir -p ~/.claude/skills/
   cp -r skills/standup ~/.claude/skills/standup-test
   ```

3. **動作確認**
   - `/standup morning` を実行
   - 情報が正しく収集されるか確認
   - 朝会が自然に進行するか確認

4. **エラーケースのテスト**
   - Git リポジトリでない場所で実行
   - GitHub CLI がない環境で実行
   - コミットがない場合

### GitHub リポジトリ

- [x] リポジトリが public
- [x] README が充実している
- [ ] GitHub Topics を設定
  - `claude-code-skill`
  - `standup`
  - `scrum`
  - `productivity`
- [ ] Releases を作成（v1.0.0）

### npm パッケージ（オプション）

- [ ] npm に公開
  ```bash
  npm publish
  ```

## 📝 公開手順

### 1. GitHub リポジトリの準備

```bash
# タグを作成
git tag -a v1.0.0 -m "Initial release for skill marketplace"
git push origin v1.0.0

# GitHub Releases を作成
# https://github.com/t1k2a/claude-hurikaeri/releases/new
```

### 2. スキルマーケットプレイスへの申請

Claude Code のスキルマーケットプレイスに申請する方法：

1. **Claude Code で申請**
   - Claude Code を開く
   - スキルマーケットプレイスにアクセス
   - 「Submit Skill」または申請フォームから登録

2. **必要情報**
   - リポジトリ URL: `https://github.com/t1k2a/claude-hurikaeri`
   - スキル名: `claude-hurikaeri`
   - カテゴリ: Productivity
   - 説明: `.claude-plugin/README.md` の内容

### 3. レビュー待ち

- スキルマーケットプレイスのレビューチームが審査
- 通常 1〜3 営業日程度
- フィードバックがあれば対応

### 4. 公開完了

- レビュー承認後、自動的にマーケットプレイスに公開
- ユーザーが検索・インストール可能に

## 🎯 公開後のタスク

- [ ] Twitter/SNS で告知
- [ ] ブログ記事を書く
- [ ] フィードバックの収集
- [ ] Issue/PR への対応
- [ ] 定期的なメンテナンス

## 📊 メトリクス

公開後、以下を追跡すると良いでしょう：

- GitHub Star 数
- ダウンロード数（npm の場合）
- Issue/PR の数
- ユーザーフィードバック

## 🔗 参考リンク

- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
- [Claude Code Skill Marketplace](https://claude.ai/code/marketplace)
- [GitHub: claude-hurikaeri](https://github.com/t1k2a/claude-hurikaeri)

---

**準備ができたら、チェックマークを付けていきましょう！**
