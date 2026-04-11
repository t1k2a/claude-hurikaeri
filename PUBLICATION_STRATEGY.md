# 技術記事 公開戦略

## 🎯 複数プラットフォームでの展開

### 1. Qiita（日本語・詳細版）

**対象読者**: 日本の開発者、Claude Code ユーザー

**タイトル**:
```
Claude Code スキルをマーケットプレイスに公開するまでの完全ガイド
～朝会・夕会自動化スキルの開発から SkillsMP 掲載まで～
```

**内容**: `BLOG_ARTICLE_DRAFT.md` の完全版
- 6パート構成
- コード例豊富
- ハマったポイント詳細
- 文字数: 8,000〜10,000字

**タグ**:
- `ClaudeCode`
- `Claude`
- `AgentSkills`
- `TypeScript`
- `Scrum`

---

### 2. Zenn（日本語・技術深掘り版）

**対象読者**: 技術に詳しい開発者

**タイトル**:
```
公式仕様準拠！Claude Code Plugin の正しい作り方
```

**内容**: 技術的な詳細に特化
- plugin.json の公式スキーマ解説
- ディレクトリ構造の正解
- MCP サーバーの実装
- エラーハンドリングのベストプラクティス

**文字数**: 5,000〜7,000字

**形式**: Book または Article

---

### 3. dev.to（英語・グローバル版）

**対象読者**: 海外の Claude Code ユーザー

**タイトル**:
```
Complete Guide to Publishing Claude Code Skills to the Marketplace
```

**内容**: 英語版の記事
- Introduction
- Implementation
- Official Specification Compliance
- GitHub Setup
- SkillsMP Auto-indexing
- Lessons Learned

**文字数**: 6,000〜8,000 words

**タグ**:
- `#claudecode`
- `#ai`
- `#typescript`
- `#opensource`
- `#devtools`

---

### 4. note（日本語・ストーリー版）

**対象読者**: ビジネスパーソン、非技術者寄り

**タイトル**:
```
毎日の朝会・夕会が変わる！Claude Code で作った自動化ツール
```

**内容**: 技術的詳細は控えめに、ストーリー重視
- なぜ作ったか（課題）
- どう解決したか（ソリューション）
- 使ってみた感想（ベネフィット）
- 誰でも使える方法

**文字数**: 3,000〜4,000字

**対象**: 有料マガジン or 無料公開

---

### 5. Medium（英語・ストーリー版）

**対象読者**: グローバルなビジネス・テック読者

**タイトル**:
```
How I Automated Daily Standups with Claude Code
A developer's journey building an AI-powered scrum master
```

**内容**: dev.to よりストーリー重視
- The Problem
- The Solution
- Building the Skill
- Lessons & Impact

**文字数**: 4,000〜5,000 words

---

### 6. YouTube（動画・デモ版）

**対象読者**: ビジュアル学習者

**タイトル**:
```
【Claude Code】朝会・夕会を自動化するスキルを作ってみた
```

**内容**: 実際の動作デモ
1. イントロ（30秒）
2. 課題説明（1分）
3. デモ実演（3分）
   - /standup morning の実行
   - 情報収集の様子
   - 会話の流れ
4. インストール方法（1分）
5. まとめ（30秒）

**長さ**: 6〜8分

**サムネイル**: インパクトのあるデザイン

---

## 📅 公開スケジュール案

### Week 1: 日本語記事

| 日 | プラットフォーム | アクション |
|----|----------------|-----------|
| Day 1 | Qiita | 詳細版を公開 |
| Day 2 | Zenn | 技術深掘り版を公開 |
| Day 3 | note | ストーリー版を公開 |
| Day 4-5 | Twitter | 記事の宣伝、スクショ共有 |
| Day 6-7 | フィードバック収集 | コメント返信、改善 |

### Week 2: 英語記事 & 拡散

| 日 | プラットフォーム | アクション |
|----|----------------|-----------|
| Day 8 | dev.to | 英語版を公開 |
| Day 9 | Medium | ストーリー版を公開 |
| Day 10 | Reddit | r/ClaudeAI, r/programming に投稿 |
| Day 11 | YouTube | デモ動画公開 |
| Day 12-14 | プロモーション | SNS、Discord、フォーラム |

---

## 🎨 記事の差別化ポイント

### Qiita/Zenn（日本語）

**強み**:
- 日本語で詳細解説
- コード例が豊富
- ハマったポイント共有
- 実践的なチェックリスト

**差別化**:
- 公式ドキュメントの日本語解説
- jq 依存問題などの実際のトラブル
- GitHub Topics 自動設定スクリプト

### dev.to/Medium（英語）

**強み**:
- グローバルリーチ
- SEO に強い
- Claude Code コミュニティへの貢献

**差別化**:
- Official specification compliance
- Auto-indexing mechanism explanation
- Real-world troubleshooting

### note/YouTube（ストーリー）

**強み**:
- 技術的ハードルが低い
- ビジュアルで分かりやすい
- ビジネス価値の訴求

**差別化**:
- 実際のユースケース
- ビフォーアフター
- ROI（時間短縮）の提示

---

## 📊 成功指標（KPI）

### Qiita
- LGTM: 50+ 目標
- ストック: 30+ 目標
- PV: 1,000+ 目標

### Zenn
- いいね: 100+ 目標
- PV: 500+ 目標

### dev.to
- Reactions: 50+ 目標
- Views: 2,000+ 目標

### GitHub
- スター: 10+ 目標（Week 2 終了時）
- フォーク: 3+ 目標

### SkillsMP
- 掲載: Week 1 中
- 検索順位: "standup" で上位10位以内

---

## 🔗 相互リンク戦略

各記事で相互にリンクを張る：

```markdown
📚 関連記事:
- [Qiita] 詳細実装ガイド
- [Zenn] 公式仕様準拠の技術解説
- [dev.to] English version
- [YouTube] デモ動画
- [GitHub] ソースコード
```

---

## 🎯 SNS 投稿テンプレート

### Twitter/X

**投稿1（記事公開時）**:
```
🎉 Claude Code スキルをマーケットプレイスに公開する方法を記事にまとめました！

朝会・夕会を自動化するスキルの開発から SkillsMP 掲載までの完全ガイドです。

✅ 公式仕様準拠
✅ ハマったポイント共有
✅ GitHub Topics 自動設定

#ClaudeCode #AgentSkills
https://qiita.com/...
```

**投稿2（デモ）**:
```
📝 実際の動作はこんな感じです

/standup morning → 過去24時間のコミット、差分、PR を自動収集
→ スクラムマスターとして朝会を進行

GitHub CLI なしでも動作します！

[スクリーンショット]

#ClaudeCode
```

**投稿3（技術詳細）**:
```
🔧 plugin.json の書き方、間違えていませんか？

❌ displayName, category, requirements
→ 公式スキーマに存在しない

✅ name, version, description, author
→ これが正解

詳しくは記事で👇
#ClaudeCode
```

### Reddit

**r/ClaudeAI**:
```
[Tool] I built a daily standup skill for Claude Code

Automatically collects Git commits, diffs, and PR info, then acts as a scrum master for morning/evening standups.

Features:
- Auto git/GitHub info collection
- Morning/evening modes
- Works without GitHub CLI

Feedback welcome!
[GitHub link]
```

---

## 📝 記事執筆チェックリスト

### 公開前確認

- [ ] タイトルは魅力的か
- [ ] 導入で読者の関心を引けているか
- [ ] コード例は動作確認済みか
- [ ] スクリーンショットは鮮明か
- [ ] リンクは正しいか
- [ ] 誤字脱字チェック
- [ ] タグは適切か

### 公開後アクション

- [ ] SNS でシェア（Twitter, LinkedIn, Facebook）
- [ ] Discord/Slack コミュニティで共有
- [ ] awesome-claude-skills に PR
- [ ] コメント返信
- [ ] アナリティクス確認

---

## 🚀 最終目標

**Week 1-2:**
- Qiita/Zenn で日本コミュニティに認知
- dev.to/Medium でグローバル展開
- GitHub スター 10+
- SkillsMP 掲載

**Week 3-4:**
- ユーザーフィードバック収集
- 改善バージョン（v1.1.0）リリース
- 追加記事（改善ポイント、ユーザー事例）

**Long-term:**
- Claude Code 公式ブログでの紹介（可能なら）
- カンファレンス発表（LT など）
- 他のスキル開発者とのコラボ

---

**さあ、記事を書いて世界に発信しましょう！** 🚀
