# AgentForge Phase 1: 認知獲得・導線設置 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `claude-hurikaeri` をマーケットプレイスに登録できる形に整備し、問い合わせ導線を設置する

**Architecture:** README を英日バイリンガル化し、マーケットプレイスバッジ・問い合わせ導線を追加。GitHub Discussions を有効化して問い合わせ窓口とする。

**Tech Stack:** Markdown, GitHub CLI (`gh`), GitHub Discussions

---

## File Map

| ファイル | 操作 | 内容 |
|----------|------|------|
| `README.md` | Modify | 英語サマリー・バッジ・問い合わせ導線を追加 |

---

### Task 1: README に英語サマリーセクションを追加する

**Files:**
- Modify: `README.md`

- [ ] **Step 1: README 先頭に英語サマリーを挿入する**

`README.md` の1行目（`# Claude Standup（朝会・夕会アシスタント）`）の直後に以下を追加する：

```markdown
# Claude Standup（朝会・夕会アシスタント）

> **English summary:** A Claude Code skill that auto-collects your GitHub activity (commits, diffs, PRs) and runs daily standup meetings (morning planning + evening retrospective) as a scrum master. Supports `/standup morning` and `/standup evening` commands.
>
> Compatible with: Claude Code, OpenAI Codex CLI, Gemini CLI
```

- [ ] **Step 2: 変更を確認する**

```bash
head -10 README.md
```

期待出力: 英語サマリーが2〜5行目に表示される

- [ ] **Step 3: コミットする**

```bash
git add README.md
git commit -m "docs: add English summary to README for marketplace visibility"
```

---

### Task 2: マーケットプレイスバッジを追加する

**Files:**
- Modify: `README.md`

- [ ] **Step 1: 英語サマリーの直下にバッジ行を追加する**

英語サマリーブロックの直後（日本語タイトルの前）に以下を挿入する：

```markdown
[![Claude Code Skill](https://img.shields.io/badge/Claude%20Code-Skill-blue?logo=anthropic)](https://github.com/t1k2a/claude-hurikaeri)
[![skillsmp](https://img.shields.io/badge/skillsmp-Listed-green)](https://skillsmp.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
```

- [ ] **Step 2: バッジが正しく追加されているか確認する**

```bash
grep "shields.io" README.md
```

期待出力: 3行のバッジ行が表示される

- [ ] **Step 3: コミットする**

```bash
git add README.md
git commit -m "docs: add marketplace and license badges to README"
```

---

### Task 3: 問い合わせ導線（Custom Setup セクション）を追加する

**Files:**
- Modify: `README.md`

- [ ] **Step 1: README 末尾（## ライセンス の直前）に問い合わせセクションを追加する**

```markdown
## Custom Setup / カスタム構築のご相談

Claude Code エージェントチームの自社導入・カスタム構築を承っています。

- GitHub Discussions でお気軽にご相談ください → [Discussions を開く](https://github.com/t1k2a/claude-hurikaeri/discussions)
- 対応内容: Agent Team のセットアップ、カスタムエージェント開発、運用保守

> **For English speakers:** We offer consulting for custom Claude Code agent team setup. Open a Discussion or reach out via GitHub.

```

- [ ] **Step 2: セクションが追加されているか確認する**

```bash
grep -n "Custom Setup" README.md
```

期待出力: 行番号と "Custom Setup / カスタム構築のご相談" が表示される

- [ ] **Step 3: コミットする**

```bash
git add README.md
git commit -m "docs: add custom setup inquiry section with Discussions link"
```

---

### Task 4: GitHub Discussions を有効化する

**Files:**
- なし（GitHub リポジトリ設定の変更）

- [ ] **Step 1: gh CLI で Discussions 機能を有効化する**

```bash
gh api repos/t1k2a/claude-hurikaeri \
  --method PATCH \
  --field has_discussions=true \
  --jq '.has_discussions'
```

期待出力: `true`

- [ ] **Step 2: 有効化を確認する**

```bash
gh repo view t1k2a/claude-hurikaeri --json hasDiscussionsEnabled --jq '.hasDiscussionsEnabled'
```

期待出力: `true`

- [ ] **Step 3: 「Custom Setup のご相談」カテゴリを作成する**

```bash
gh api graphql -f query='
mutation {
  createDiscussionCategory(input: {
    repositoryId: "'"$(gh repo view t1k2a/claude-hurikaeri --json id --jq '.id')"'",
    name: "Custom Setup / お問い合わせ",
    description: "エージェントチームのカスタム構築・導入相談",
    emoji: ":briefcase:",
    color: BLUE
  }) {
    discussionCategory { id name }
  }
}'
```

失敗した場合（API制限など）: GitHub UI から手動で Discussions > New category を作成する。

- [ ] **Step 4: 動作確認（ブラウザ確認）**

`https://github.com/t1k2a/claude-hurikaeri/discussions` を開き、Discussions タブが表示されることを確認する。

---

### Task 5: すべての変更を push する

- [ ] **Step 1: 現在の状態を確認する**

```bash
git log --oneline -5
git status
```

- [ ] **Step 2: origin/main に push する**

```bash
git push origin main
```

期待出力: `main -> main` の push 成功メッセージ

- [ ] **Step 3: GitHub 上で README が正しく表示されているか確認する**

```bash
gh repo view t1k2a/claude-hurikaeri --web
```

ブラウザで以下を確認する:
- 英語サマリーが表示されている
- バッジが3つ表示されている
- "Custom Setup" セクションが表示されている
- Discussions タブが表示されている

---

## 完了基準

- [ ] README に英語サマリーが追加されている
- [ ] バッジ（Claude Code Skill / skillsmp / MIT）が表示されている
- [ ] "Custom Setup / カスタム構築のご相談" セクションがある
- [ ] GitHub Discussions が有効化されている
- [ ] すべての変更が main ブランチに push されている

---

## Phase 1 完了後の次のアクション（Phase 2 準備）

1. skillsmp.com に手動登録（ブラウザから）
2. claudemarketplaces.com に手動登録
3. Zenn / Qiita に技術記事を投稿（エージェントチームの仕組み）
