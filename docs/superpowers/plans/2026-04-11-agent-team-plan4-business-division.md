# 自律エージェントチーム - Plan 4: Business Division Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 毎週月曜に競合調査・成長分析・コンテンツ生成を自動実行する Business Division を構築する。

**Architecture:** Business Division orchestrator が Researcher → Analyst → Marketer を順番に呼び出す。各エージェントの出力は次のエージェントへ引き継がれ、最終成果物（SNS投稿・ブログ下書き等）を `~/.claude/skills/agent-team/business-log.md` に保存する。

**Tech Stack:** Claude Code (superpowers), SKILL.md files, Agent tool, WebSearch, gh CLI（GitHub API）

> **前提:** Plan 1（Foundation）が完了していること。`~/.claude/skills/agent-team/SKILL.md` の `_run business` が PLACEHOLDER のままであること。

---

## File Structure

| ファイル | 役割 |
|---------|------|
| `skills/agent-team/agents/researcher/SKILL.md` | Researcher Agent — 競合・チャネル調査 |
| `skills/agent-team/agents/analyst/SKILL.md` | Analyst Agent — GitHub統計・成長指標分析 |
| `skills/agent-team/agents/marketer/SKILL.md` | Marketer Agent — 告知文・SNS投稿・ブログ下書き生成 |
| `skills/agent-team/agents/business-division/SKILL.md` | Business Division orchestrator |
| `skills/agent-team/SKILL.md` | `_run business` セクションを更新（PLACEHOLDER → 実際の呼び出し） |

**中継ファイル（状態共有）:**
- `~/.claude/skills/agent-team/business-log.md` — 週次レポート（最新3件保持）

---

### Task 1: Researcher Agent を実装する

**Files:**
- Create: `skills/agent-team/agents/researcher/SKILL.md`

- [ ] **Step 1: ディレクトリを作成する**

```bash
mkdir -p /home/joji/claude-hurikaeri/skills/agent-team/agents/researcher
```

- [ ] **Step 2: SKILL.md を以下の内容で作成する**

`/home/joji/claude-hurikaeri/skills/agent-team/agents/researcher/SKILL.md`:

```markdown
---
name: agent-team-researcher
description: >
  Business Division Researcher Agent. 競合サービスと拡散チャネルを週次で調査し、
  Analyst・Marketer が使う調査レポートを生成する。
  Business Division orchestrator から Agent tool で呼ばれる。
---

# Researcher Agent

このリポジトリのサービス・プロダクトについて競合調査とチャネル調査を行い、レポートを生成する。

## Step 1: プロジェクト概要を把握する

`README.md` を Read ツールで読んでプロダクトの概要（名前・目的・ターゲット）を把握する。
README が存在しない場合は `package.json` または `pyproject.toml` を読む。

## Step 2: 競合サービスを調査する

WebSearch ツールで以下を検索する（プロダクト名・カテゴリに合わせてキーワードを調整する）：

1. `<プロダクト名> alternatives 2025` — 直接競合のリストを把握する
2. `<カテゴリ> tools comparison 2025` — 市場全体の選択肢を把握する
3. `<プロダクト名> review` — ユーザー評価・強み・弱みを把握する

各検索で得た情報から以下を抽出する：
- 主要競合3〜5件（名前・特徴・価格帯）
- 競合との差別化ポイント（自プロダクトの強みと弱み）

## Step 3: 拡散チャネルを調査する

WebSearch ツールで以下を検索する：

1. `<プロダクト名> site:reddit.com` — Reddit での言及・スレッドを確認する
2. `<プロダクト名> site:news.ycombinator.com` — Hacker News での言及を確認する
3. `<カテゴリ> github trending` — GitHub トレンド上の類似プロダクトを確認する

得た情報から以下を抽出する：
- 活発なコミュニティ・チャネル（Reddit/HN/Twitter等）
- 拡散に使えそうなコンテンツ形式（技術記事・デモ動画・比較記事等）

## Step 4: 調査レポートを生成する

以下の形式でレポートを出力する：

```
## Researcher 調査レポート

### 調査日時
<ISO8601 日時>

### プロダクト概要
<README から把握した概要>

### 競合調査
#### 主要競合
1. <競合名> — <特徴> （価格: <価格帯>）
2. <競合名> — <特徴> （価格: <価格帯>）
3. <競合名> — <特徴> （価格: <価格帯>）

#### 差別化ポイント
- 強み: <自プロダクトの優位点>
- 弱み: <改善が必要な点>

### チャネル調査
#### 活発なコミュニティ
- <チャネル名>: <概要・URL>

#### 推奨コンテンツ形式
- <形式>: <理由>
```

このレポートはそのまま Analyst Agent と Marketer Agent に引き継がれる。
```

- [ ] **Step 3: 確認**

```bash
wc -l /home/joji/claude-hurikaeri/skills/agent-team/agents/researcher/SKILL.md
```

Expected: 70行以上

- [ ] **Step 4: Commit**

```bash
git -C /home/joji/claude-hurikaeri add skills/agent-team/agents/researcher/
git -C /home/joji/claude-hurikaeri commit -m "feat: researcher agent SKILL.md"
```

---

### Task 2: Analyst Agent を実装する

**Files:**
- Create: `skills/agent-team/agents/analyst/SKILL.md`

- [ ] **Step 1: ディレクトリを作成する**

```bash
mkdir -p /home/joji/claude-hurikaeri/skills/agent-team/agents/analyst
```

- [ ] **Step 2: SKILL.md を以下の内容で作成する**

`/home/joji/claude-hurikaeri/skills/agent-team/agents/analyst/SKILL.md`:

```markdown
---
name: agent-team-analyst
description: >
  Business Division Analyst Agent. GitHub 統計と成長指標を分析し、
  Marketer が使う分析レポートを生成する。
  Business Division orchestrator から Agent tool で呼ばれる。
argument-hint: "<Researcher の調査レポート>"
---

# Analyst Agent

$ARGUMENTS（Researcher の調査レポート）を受け取り、GitHub 統計・成長指標を分析する。

$ARGUMENTS が空の場合は Researcher レポートなしで分析を進める。

## Step 1: GitHub 統計を収集する

```bash
# リポジトリ情報（スター数・フォーク数・ウォッチャー数）
gh api repos/{owner}/{repo} --jq '{stars: .stargazers_count, forks: .forks_count, watchers: .watchers_count, open_issues: .open_issues_count}' 2>/dev/null \
  || git remote get-url origin 2>/dev/null

# 直近4週間のコミット活動
git log --oneline --since="4 weeks ago" --no-merges 2>/dev/null | wc -l

# 直近4週間のコントリビューター数
git log --since="4 weeks ago" --format="%ae" 2>/dev/null | sort -u | wc -l

# オープン Issue 数と PR 数
gh issue list --state open --json number --jq 'length' 2>/dev/null || echo "gh not available"
gh pr list --state open --json number --jq 'length' 2>/dev/null || echo "gh not available"
```

`{owner}/{repo}` は `git remote get-url origin` の出力から GitHub のオーナーとリポジトリ名を抽出して置き換える。

## Step 2: 成長トレンドを分析する

直近4週間と以前の4週間を比較する：

```bash
# 直近4週間
git log --oneline --since="4 weeks ago" --before="now" --no-merges 2>/dev/null | wc -l

# 以前の4週間（4〜8週前）
git log --oneline --since="8 weeks ago" --before="4 weeks ago" --no-merges 2>/dev/null | wc -l
```

コミット数の増減からプロジェクト活動量のトレンドを判定する（増加/横ばい/減少）。

## Step 3: $ARGUMENTS の競合情報と照合する

$ARGUMENTS（Researcher レポート）が提供されている場合：
- 競合の強みと自プロダクトの現状を照合する
- 成長指標が競合に対して優勢か劣勢かを判断する

## Step 4: 分析レポートを生成する

```
## Analyst 分析レポート

### 分析日時
<ISO8601 日時>

### GitHub 統計
- スター数: <数>
- フォーク数: <数>
- オープン Issue: <数>
- オープン PR: <数>
- 直近4週コミット数: <数>

### 成長トレンド
- コミット活動: <増加/横ばい/減少>（直近4週: <数> vs 以前4週: <数>）
- 総合評価: <健全/注意/要改善>

### 競合との比較（Researcher データあり の場合）
- <競合名> に対して: <優勢/劣勢> — <理由>

### マーケティングへの示唆
- <Marketer Agent が活用すべきポイント>
```

このレポートはそのまま Marketer Agent に引き継がれる。
```

- [ ] **Step 3: 確認**

```bash
wc -l /home/joji/claude-hurikaeri/skills/agent-team/agents/analyst/SKILL.md
```

Expected: 75行以上

- [ ] **Step 4: Commit**

```bash
git -C /home/joji/claude-hurikaeri add skills/agent-team/agents/analyst/
git -C /home/joji/claude-hurikaeri commit -m "feat: analyst agent SKILL.md"
```

---

### Task 3: Marketer Agent を実装する

**Files:**
- Create: `skills/agent-team/agents/marketer/SKILL.md`

- [ ] **Step 1: ディレクトリを作成する**

```bash
mkdir -p /home/joji/claude-hurikaeri/skills/agent-team/agents/marketer
```

- [ ] **Step 2: SKILL.md を以下の内容で作成する**

`/home/joji/claude-hurikaeri/skills/agent-team/agents/marketer/SKILL.md`:

```markdown
---
name: agent-team-marketer
description: >
  Business Division Marketer Agent. Researcher と Analyst のレポートをもとに
  告知文・SNS投稿・ブログ下書きを生成する。
  Business Division orchestrator から Agent tool で呼ばれる。
argument-hint: "<Researcher レポート>\n---\n<Analyst レポート>"
---

# Marketer Agent

$ARGUMENTS（Researcher レポートと Analyst レポートを `---` で区切ったもの）を受け取り、コンテンツを生成する。

$ARGUMENTS が空の場合は git log から直近の変更を確認してコンテンツを生成する。

## Step 1: インプットを整理する

$ARGUMENTS から以下の情報を抽出する：
- プロダクト概要・差別化ポイント（Researcher レポートより）
- 成長トレンド・強調できる指標（Analyst レポートより）
- 活発なチャネル・推奨コンテンツ形式（Researcher レポートより）

$ARGUMENTS がない場合は、`README.md` を Read ツールで読みプロダクト概要を把握する。

## Step 2: SNS 投稿文を生成する（Twitter/X 形式）

以下の条件で3パターン生成する：
- 280文字以内（英語）または 140文字以内（日本語）
- 1つ目: 機能・技術的な訴求（開発者向け）
- 2つ目: 価値・メリットの訴求（ユーザー向け）
- 3つ目: 数字・実績の訴求（スター数・コミット数など具体的な指標を使用）

```
## SNS 投稿案

### パターン1（開発者向け）
<投稿文>

### パターン2（ユーザー向け）
<投稿文>

### パターン3（数字・実績）
<投稿文>
```

## Step 3: ブログ記事の下書きを生成する

以下の構成でブログ記事の下書きを作成する（800〜1200字程度）：

```
# <プロダクト名> — <キャッチコピー>

## TL;DR
<3行以内の要約>

## 背景・課題
<解決する問題の説明>

## 特徴・差別化ポイント
<競合との違いを具体的に記述>

## 使い方（Quick Start）
<簡潔なインストール・使用手順 — README から抽出>

## まとめ
<行動喚起（GitHub スター・試用・フィードバック）>
```

## Step 4: Reddit/HN 投稿文を生成する（チャネルがある場合）

Researcher レポートに Reddit または HN の活発なコミュニティが含まれる場合のみ生成する：

```
## コミュニティ投稿案

### Show HN タイトル案
Show HN: <プロダクト名> – <一行説明>

### Reddit r/<subreddit> 投稿文
**タイトル:** <タイトル>
**本文:** <投稿文（500字程度）>
```

## Step 5: 結果を出力する

```
## Marketer 完了報告

### SNS 投稿案
<Step 2 の内容>

### ブログ下書き
<Step 3 の内容>

### コミュニティ投稿案
<Step 4 の内容、またはチャネルなしの場合「なし」>

### ステータス
DONE
```
```

- [ ] **Step 3: 確認**

```bash
wc -l /home/joji/claude-hurikaeri/skills/agent-team/agents/marketer/SKILL.md
```

Expected: 85行以上

- [ ] **Step 4: Commit**

```bash
git -C /home/joji/claude-hurikaeri add skills/agent-team/agents/marketer/
git -C /home/joji/claude-hurikaeri commit -m "feat: marketer agent SKILL.md"
```

---

### Task 4: Business Division orchestrator を実装する

**Files:**
- Create: `skills/agent-team/agents/business-division/SKILL.md`

- [ ] **Step 1: ディレクトリを作成する**

```bash
mkdir -p /home/joji/claude-hurikaeri/skills/agent-team/agents/business-division
```

- [ ] **Step 2: SKILL.md を以下の内容で作成する**

`/home/joji/claude-hurikaeri/skills/agent-team/agents/business-division/SKILL.md`:

```markdown
---
name: agent-team-business
description: >
  Business Division orchestrator. Researcher → Analyst → Marketer を順番に実行し、
  成果物を business-log.md に保存する。
  Chief Orchestrator から Agent tool で呼ばれる。
---

# Business Division

## Step 1: Researcher Agent を呼ぶ

`~/.claude/skills/agent-team/agents/researcher/SKILL.md` を Read ツールで読む。

そのプロンプトで Agent tool を起動する：
- subagent_type: general-purpose
- prompt: [researcher/SKILL.md の内容]

Researcher の出力（`## Researcher 調査レポート` 以降の全文）を保持する。

Researcher が失敗した場合（出力が `## Researcher 調査レポート` を含まない）：
「Researcher Agent が失敗しました。空のレポートで Analyst・Marketer を続行します。」と記録して続行する。

## Step 2: Analyst Agent を呼ぶ

`~/.claude/skills/agent-team/agents/analyst/SKILL.md` を Read ツールで読む。

Step 1 の Researcher レポートを $ARGUMENTS として Agent tool で起動する：
- subagent_type: general-purpose
- prompt: Read ツールで読んだ analyst/SKILL.md の内容全文を先頭に置き、末尾に以下を追記する：
  ```
  $ARGUMENTS: [Step 1 の Researcher レポート全文]
  ```

Analyst の出力（`## Analyst 分析レポート` 以降の全文）を保持する。

Analyst が失敗した場合：「Analyst Agent が失敗しました。空の分析で Marketer を続行します。」と記録して続行する。

## Step 3: Marketer Agent を呼ぶ

`~/.claude/skills/agent-team/agents/marketer/SKILL.md` を Read ツールで読む。

Step 1 の Researcher レポートと Step 2 の Analyst レポートを結合して $ARGUMENTS として Agent tool で起動する：
- subagent_type: general-purpose
- prompt: Read ツールで読んだ marketer/SKILL.md の内容全文を先頭に置き、末尾に以下を追記する：
  ```
  $ARGUMENTS: [Step 1 の Researcher レポート全文]
  ---
  [Step 2 の Analyst レポート全文]
  ```

Marketer の出力（`## Marketer 完了報告` 以降の全文）を保持する。

## Step 4: business-log.md に保存する

`~/.claude/skills/agent-team/business-log.md` を Read ツールで読む（存在しない場合は空として扱う）。

以下の形式で先頭に今週のレポートを追記し、古いエントリが4件以上ある場合は末尾のエントリを削除して最新3件のみ保持する：

```
# Business Division レポート

---

## <ISO8601 日時>

### Researcher レポート
[Step 1 の Researcher レポート]

### Analyst レポート
[Step 2 の Analyst レポート]

### Marketer 成果物
[Step 3 の Marketer 完了報告]

---

[以前のエントリ（最大2件）]
```

Edit ツールで `~/.claude/skills/agent-team/business-log.md` を書き込む（ファイルが存在しない場合は Write ツールを使う）。

## Step 5: 完了を報告する

```
Business Division 完了報告:
- Researcher: 完了
- Analyst: 完了
- Marketer: 完了
- レポート保存先: ~/.claude/skills/agent-team/business-log.md
- 実行日時: <ISO8601 日時>
```
```

- [ ] **Step 3: 確認**

```bash
wc -l /home/joji/claude-hurikaeri/skills/agent-team/agents/business-division/SKILL.md
```

Expected: 60行以上

- [ ] **Step 4: Commit**

```bash
git -C /home/joji/claude-hurikaeri add skills/agent-team/agents/business-division/
git -C /home/joji/claude-hurikaeri commit -m "feat: business-division orchestrator SKILL.md (Researcher→Analyst→Marketer)"
```

---

### Task 5: Chief Orchestrator の `_run business` を更新し、グローバルインストールする

**Files:**
- Modify: `skills/agent-team/SKILL.md`

- [ ] **Step 1: 現在の `_run business` セクションを確認する**

```bash
grep -n "PLACEHOLDER\|_run business\|Business Division" /home/joji/claude-hurikaeri/skills/agent-team/SKILL.md
```

- [ ] **Step 2: `_run business` セクションを更新する**

Read ツールで `skills/agent-team/SKILL.md` を読み、以下の部分を Edit ツールで置き換える。

現在の内容：
```
### _run business（Business Division を実行）

起動時チェックを通過後、以下を出力して終了：
```
[Business Division] PLACEHOLDER - Plan 4 で実装予定
```
```

置き換え後：
```
### _run business（Business Division を実行）

起動時チェックを通過後、以下を実行する：

1. `~/.claude/skills/agent-team/agents/business-division/SKILL.md` を Read ツールで読む。
2. そのプロンプト内容で Agent tool を起動する（subagent_type: general-purpose）。
3. Business Division からの完了報告を出力する。
```

- [ ] **Step 3: Commit**

```bash
git -C /home/joji/claude-hurikaeri add skills/agent-team/SKILL.md
git -C /home/joji/claude-hurikaeri commit -m "feat: _run business を business-division orchestrator の実際の呼び出しに更新"
```

- [ ] **Step 4: グローバルインストールを更新する**

```bash
cp -r /home/joji/claude-hurikaeri/skills/agent-team/. ~/.claude/skills/agent-team/
```

- [ ] **Step 5: ファイル構造を確認する**

```bash
find ~/.claude/skills/agent-team -name "SKILL.md" | sort
```

Expected（Plan 3 の10ファイル + 4ファイル = 14ファイル）:
```
~/.claude/skills/agent-team/SKILL.md
~/.claude/skills/agent-team/agents/analyst/SKILL.md
~/.claude/skills/agent-team/agents/business-division/SKILL.md
~/.claude/skills/agent-team/agents/coder/SKILL.md
~/.claude/skills/agent-team/agents/dev-division/SKILL.md
~/.claude/skills/agent-team/agents/incident/SKILL.md
~/.claude/skills/agent-team/agents/marketer/SKILL.md
~/.claude/skills/agent-team/agents/monitor/SKILL.md
~/.claude/skills/agent-team/agents/ops-division/SKILL.md
~/.claude/skills/agent-team/agents/perf/SKILL.md
~/.claude/skills/agent-team/agents/planner/SKILL.md
~/.claude/skills/agent-team/agents/pr-creator/SKILL.md
~/.claude/skills/agent-team/agents/researcher/SKILL.md
~/.claude/skills/agent-team/agents/tester/SKILL.md
```

- [ ] **Step 6: `_run business` が PLACEHOLDER でないことを確認する**

```bash
grep -A5 "_run business" ~/.claude/skills/agent-team/SKILL.md | head -8
```

Expected: PLACEHOLDER の行が消えて `business-division/SKILL.md` の Read が記述されている

---

## 完了チェックリスト

- [ ] `skills/agent-team/agents/researcher/SKILL.md` が作成されている（WebSearch・競合調査・チャネル調査）
- [ ] `skills/agent-team/agents/analyst/SKILL.md` が作成されている（GitHub統計・成長トレンド）
- [ ] `skills/agent-team/agents/marketer/SKILL.md` が作成されている（SNS投稿・ブログ下書き・HN/Reddit案）
- [ ] `skills/agent-team/agents/business-division/SKILL.md` が作成されている（Researcher→Analyst→Marketerの順次実行）
- [ ] `skills/agent-team/SKILL.md` の `_run business` が更新されている
- [ ] `~/.claude/skills/agent-team/` にグローバルインストール済み（14ファイル）

---

## 次のステップ

Plan 4 完了後、Plan 5（Leadership Division）に進む。
Plan 5 では以下を実装する：
- PM Agent（チーム状況集約・Issue化）
- 経営 Agent（マネタイズ評価・要望リスト生成）
- Leadership Division orchestrator
- 日次 CronJob の追加
