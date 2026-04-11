# 自律エージェントチーム - Plan 5: Leadership Division Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** PM Agent と経営 Agent を実装し、日次で「チーム状況集約 → 経営へ報告 → 要望受け取り → Issue 化」の双方向フローを自律実行する Leadership Division を構築する。

**Architecture:** Leadership Division orchestrator が日次 CronJob で起動し、PM Agent → 経営 Agent → PM Agent の順に呼び出す。PM はチーム状況集約・QA・Issue化を担い、経営はマネタイズ観点から要望を決定する。中継ファイル `leadership-log.md` でデイリーレポートを保持する。

**Tech Stack:** Claude Code (superpowers), SKILL.md files, Agent tool, GitHub CLI (gh), git, WebSearch（経営 Agent のマーケット調査用）

> **前提:** Plan 1（Foundation）が完了していること。Plan 3, 4（Ops/Business Division）は Leadership より先でも後でも構わない（独立している）。

---

## File Structure

| ファイル | 役割 |
|---------|------|
| `skills/agent-team/agents/leadership-division/SKILL.md` | Leadership Division orchestrator |
| `skills/agent-team/agents/pm/SKILL.md` | PM Agent — 状況集約・QA・Issue化・経営への報告 |
| `skills/agent-team/agents/management/SKILL.md` | 経営 Agent — マネタイズ評価・要望決定 |
| `~/.claude/skills/agent-team/leadership-log.md` | デイリーレポート履歴（ランタイム生成、最新5件保持） |
| `skills/agent-team/SKILL.md` | `_run leadership` セクションを更新（PLACEHOLDER → 実際の呼び出し） |

---

### Task 1: PM Agent を実装する

**Files:**
- Create: `skills/agent-team/agents/pm/SKILL.md`

- [ ] **Step 1: ディレクトリを作成する**

```bash
mkdir -p /home/joji/claude-hurikaeri/skills/agent-team/agents/pm
```

- [ ] **Step 2: SKILL.md を以下の内容で作成する**

`/home/joji/claude-hurikaeri/skills/agent-team/agents/pm/SKILL.md`:

```markdown
---
name: agent-team-pm
description: >
  Leadership Division PM. チーム状況を集約して経営 Agent に報告し、
  経営からの要望を GitHub Issue に変換する。QA・バグ発見・リファクタ提案も行う。
  Leadership Division orchestrator から Agent tool で呼ばれる。
argument-hint: "[report|post_report <経営Agentの返答テキスト>]"
---

# PM Agent

$ARGUMENTS を確認して動作を切り替える：
- `report` または引数なし → Step 1〜4（状況集約 + 経営へのレポート生成）
- `post_report <経営Agentの返答>` → Step 5（経営の要望を Issue 化）

---

## report モード（チーム状況集約 → レポート生成）

### Step 1: チーム状況を集約する

**Git 状況:**
```bash
git log --oneline --since="24 hours ago" --no-merges 2>/dev/null | head -20
git status --short 2>/dev/null
```

**オープン Issue・PR:**
```bash
command -v gh >/dev/null 2>&1 && gh issue list --state open --limit 10 --json number,title,labels 2>/dev/null || echo "gh not available"
command -v gh >/dev/null 2>&1 && gh pr list --state open --limit 5 --json number,title,isDraft 2>/dev/null || echo "gh not available"
```

**最近マージされた PR:**
```bash
command -v gh >/dev/null 2>&1 && gh pr list --state merged --limit 5 --json number,title,mergedAt 2>/dev/null || echo "gh not available"
```

**leadership-log.md の直近レポート（前回との差分確認用）:**
```bash
cat ~/.claude/skills/agent-team/leadership-log.md 2>/dev/null | head -50 || echo "初回レポート"
```

### Step 2: QA・動作確認を行う

最近マージされた PR や変更ファイルを確認し、以下を検討する：
- バグの可能性がある箇所（型エラー、nullチェック漏れ、テスト不足など）
- リファクタリングが望ましい箇所（重複コード、長すぎる関数など）
- セキュリティ上の懸念点

発見した場合は以下の形式で記録しておく：
```
[QA発見]
- バグ候補: <ファイル名:行番号> — <内容>
- リファクタ提案: <対象> — <理由>
```

### Step 3: QA 発見を GitHub Issue 化する

Step 2 で発見した項目があれば、1件ずつ GitHub Issue を作成する：
```bash
gh issue create \
  --title "<バグ/リファクタの概要>" \
  --body "<詳細説明>" \
  --label "agent-task,qa" 2>/dev/null || echo "gh not available - Issue 化をスキップ"
```

gh が利用できない場合は Issue 化すべき内容を出力に含めて終了する。

### Step 4: デイリーレポートを生成して出力する

以下の形式でレポートを生成し、標準出力に出力する（Leadership Division orchestrator が受け取る）：

```
## PM デイリーレポート [YYYY-MM-DD]

### チーム状況
- 直近24時間のコミット数: <N> 件
- オープン Issue: <N> 件
- オープン PR: <N> 件（うちドラフト: <N> 件）
- 直近マージ PR: <N> 件

### QA・発見事項
<発見があれば記載、なければ「異常なし」>
Issue 化した項目: <N> 件

### 注目点
<経営 Agent が判断すべき重要事項（開発の停滞、PRレビュー待ちなど）>

### サービス状態サマリー
<全体の健全性の評価（Good / Warning / Critical）とその理由>
```

---

## post_report モード（経営の要望を Issue 化）

$ARGUMENTS から `post_report ` の後のテキストを経営 Agent の返答として取得する。

### Step 5: 経営の要望を GitHub Issue に変換する

経営 Agent の返答から要望リストを抽出し、優先度順に GitHub Issue を作成する：

```bash
gh issue create \
  --title "<要望の概要>" \
  --body "## 背景\n<経営からの要望の背景>\n\n## 要件\n<具体的な要件>\n\n## 優先度\n<高/中/低>" \
  --label "agent-task,management-request" 2>/dev/null || echo "gh not available"
```

gh が利用できない場合は作成すべき Issue の内容を出力する。

### Step 6: leadership-log.md を更新する

`~/.claude/skills/agent-team/leadership-log.md` を更新する（最新5件のレポートを保持）：

Read ツールで既存の leadership-log.md を読み（なければ空として扱う）、
新しいレポートエントリを先頭に追加し、6件目以降を削除して Write ツールで保存する。

フォーマット：
```markdown
# Leadership Log

---

## [YYYY-MM-DD] PM レポート

<Step 4 のレポート内容>

## [YYYY-MM-DD] 経営 レスポンス

<経営 Agent の返答要約>

---

（以前のエントリ...）
```

### Step 7: 完了を報告する

```
PM Agent 完了:
- QA Issue 化: <N> 件
- 経営要望 Issue 化: <N> 件
- leadership-log.md 更新済み
```
```

- [ ] **Step 3: 確認**

```bash
wc -l /home/joji/claude-hurikaeri/skills/agent-team/agents/pm/SKILL.md
```

Expected: 100行以上

- [ ] **Step 4: Commit**

```bash
git -C /home/joji/claude-hurikaeri add skills/agent-team/agents/pm/
git -C /home/joji/claude-hurikaeri commit -m "feat: pm agent SKILL.md"
```

---

### Task 2: 経営 Agent を実装する

**Files:**
- Create: `skills/agent-team/agents/management/SKILL.md`

- [ ] **Step 1: ディレクトリを作成する**

```bash
mkdir -p /home/joji/claude-hurikaeri/skills/agent-team/agents/management
```

- [ ] **Step 2: SKILL.md を以下の内容で作成する**

`/home/joji/claude-hurikaeri/skills/agent-team/agents/management/SKILL.md`:

```markdown
---
name: agent-team-management
description: >
  Leadership Division 経営 Agent. PM からのデイリーレポートを受け取り、
  マネタイズ観点でサービスを評価して機能追加・修正の要望リストを返す。
  Leadership Division orchestrator から Agent tool で呼ばれる。
argument-hint: "<PM デイリーレポートテキスト>"
---

# 経営 Agent

$ARGUMENTS（PM Agent が生成したデイリーレポート）を受け取り、経営的観点から評価して要望を返す。

## Step 1: PM レポートを読む

$ARGUMENTS のテキストを以下の観点で分析する：
- サービス状態: Good / Warning / Critical の評価を確認
- 開発速度: コミット数・マージPR数は適切か
- ブロッカー: レビュー待ちや停滞している Issue はないか
- QA発見: バグ候補やリファクタ提案の深刻度

## Step 2: マネタイズ観点でサービスを評価する

以下の観点でサービスの現状を評価する：

**ユーザー価値の観点:**
- 直近の変更はユーザーにとって価値があるか
- 停滞しているユーザー向け機能はないか

**成長・収益の観点:**
- 課金・有料転換に関わる機能の進捗はどうか
- ユーザー獲得に影響する機能（オンボーディング改善等）の状況
- 競合に対して差別化できている機能はあるか

**リスクの観点:**
- Critical な QA 発見がある場合はユーザー影響を評価する
- 技術的負債の蓄積がサービス提供に影響していないか

## Step 3: 要望リストを生成する

評価をもとに、以下の形式で優先度付き要望リストを生成する：

```
## 経営レスポンス [YYYY-MM-DD]

### サービス評価
<マネタイズ観点での総評（2〜3文）>

### 要望リスト（優先度順）

#### 優先度: 高
1. <要望タイトル>
   - 背景: <なぜ必要か>
   - 期待効果: <マネタイズ/ユーザー価値への影響>

#### 優先度: 中
1. <要望タイトル>
   - 背景: <なぜ必要か>
   - 期待効果: <影響>

#### 優先度: 低（余裕があれば）
1. <要望タイトル>

### 経営からのメッセージ
<チームへの一言（モチベーション向上のため、簡潔に>
```

要望は実装可能な粒度に留める（「売上を2倍にする」ではなく「無料プランのアップグレード誘導バナーを追加する」レベル）。

## Step 4: 結果を出力する

Step 3 のレポートをそのまま標準出力として出力する。
Leadership Division orchestrator が受け取り、PM Agent の post_report モードに渡す。
```

- [ ] **Step 3: 確認**

```bash
wc -l /home/joji/claude-hurikaeri/skills/agent-team/agents/management/SKILL.md
```

Expected: 70行以上

- [ ] **Step 4: Commit**

```bash
git -C /home/joji/claude-hurikaeri add skills/agent-team/agents/management/
git -C /home/joji/claude-hurikaeri commit -m "feat: management (経営) agent SKILL.md"
```

---

### Task 3: Leadership Division orchestrator を実装する

**Files:**
- Create: `skills/agent-team/agents/leadership-division/SKILL.md`

- [ ] **Step 1: ディレクトリを作成する**

```bash
mkdir -p /home/joji/claude-hurikaeri/skills/agent-team/agents/leadership-division
```

- [ ] **Step 2: SKILL.md を以下の内容で作成する**

`/home/joji/claude-hurikaeri/skills/agent-team/agents/leadership-division/SKILL.md`:

```markdown
---
name: agent-team-leadership
description: >
  Leadership Division orchestrator. PM Agent → 経営 Agent → PM Agent(post_report) の
  順で自律実行する。Chief Orchestrator から Agent tool で呼ばれる。
---

# Leadership Division

## Step 1: PM Agent を呼ぶ（report モード）

`~/.claude/skills/agent-team/agents/pm/SKILL.md` を Read ツールで読む。

そのプロンプト内容で Agent tool を起動する：
- subagent_type: general-purpose
- prompt: [pm/SKILL.md の内容] + "\n\n$ARGUMENTS: report"

PM Agent の出力（デイリーレポートテキスト）をメモしておく。

PM Agent が失敗した場合（出力なし、エラーのみ）：
- 「PM Agent が失敗しました。Leadership Division を終了します。」と出力して終了する。

## Step 2: 経営 Agent を呼ぶ

`~/.claude/skills/agent-team/agents/management/SKILL.md` を Read ツールで読む。

Step 1 の PM レポートテキストを $ARGUMENTS として付加し、Agent tool で起動する：
- subagent_type: general-purpose
- prompt: [management/SKILL.md の内容] + "\n\n$ARGUMENTS: [PM レポートテキスト]"

経営 Agent の出力（要望リストテキスト）をメモしておく。

経営 Agent が失敗した場合：
- 「経営 Agent が失敗しました。PM レポートのみで終了します。」と出力して終了する。

## Step 3: PM Agent を呼ぶ（post_report モード）

`~/.claude/skills/agent-team/agents/pm/SKILL.md` を Read ツールで読む。

Step 2 の経営 Agent の返答を `post_report ` プレフィックス付きで $ARGUMENTS として付加し、Agent tool で起動する：
- subagent_type: general-purpose
- prompt: [pm/SKILL.md の内容] + "\n\n$ARGUMENTS: post_report [経営 Agent の返答テキスト]"

## Step 4: 完了を報告する

```
Leadership Division 完了報告:
- PM レポート: 生成済み
- 経営レスポンス: 生成済み
- Issue 化: PM Agent が実施
- leadership-log.md: 更新済み
```
```

- [ ] **Step 3: 確認**

```bash
wc -l /home/joji/claude-hurikaeri/skills/agent-team/agents/leadership-division/SKILL.md
```

Expected: 50行以上

- [ ] **Step 4: Commit**

```bash
git -C /home/joji/claude-hurikaeri add skills/agent-team/agents/leadership-division/
git -C /home/joji/claude-hurikaeri commit -m "feat: leadership-division orchestrator SKILL.md (PM→経営→PM)"
```

---

### Task 4: Chief Orchestrator に `_run leadership` を追加する

**Files:**
- Modify: `skills/agent-team/SKILL.md`

現在 `_run leadership` セクションは存在しない（または PLACEHOLDER）。これを追加/更新する。

- [ ] **Step 1: 現在のファイルを確認する**

```bash
grep -n "leadership\|_run" /home/joji/claude-hurikaeri/skills/agent-team/SKILL.md
```

- [ ] **Step 2: `_run leadership` セクションを追加する**

Read ツールで `/home/joji/claude-hurikaeri/skills/agent-team/SKILL.md` を読み、`_run business` セクションの後に以下を追加する：

```
### _run leadership（Leadership Division を実行）

起動時チェックを通過後、以下を実行する：

1. `~/.claude/skills/agent-team/agents/leadership-division/SKILL.md` を Read ツールで読む。
2. そのプロンプト内容で Agent tool を起動する（subagent_type: general-purpose）。
3. Leadership Division からの完了報告を出力する。
```

また、`/agent-team start` セクションの CronCreate に Leadership Division の Cron を追加する：

現在の CronCreate 3本（Dev/Ops/Business）に加えて：
- Leadership Division: 毎日8時57分 (`57 8 * * *`)
  - prompt: `/agent-team _run leadership`

`start` コマンドの出力メッセージも更新する：
```
- Leadership Division: 毎日9時頃起動（Cron: 57 8 * * *）
```

control.md の `cron_ids` にも `leadership: null` フィールドを追加する（start コマンドの初期化部分）。

- [ ] **Step 3: Commit**

```bash
git -C /home/joji/claude-hurikaeri add skills/agent-team/SKILL.md
git -C /home/joji/claude-hurikaeri commit -m "feat: _run leadership を追加、start コマンドに Leadership CronJob を追加"
```

---

### Task 5: グローバルインストールを更新して確認する

- [ ] **Step 1: グローバルインストールを更新する**

```bash
cp -r /home/joji/claude-hurikaeri/skills/agent-team/. ~/.claude/skills/agent-team/
```

- [ ] **Step 2: ファイル構造を確認する**

```bash
find ~/.claude/skills/agent-team -name "SKILL.md" | sort
```

Expected（9ファイル）:
```
~/.claude/skills/agent-team/SKILL.md
~/.claude/skills/agent-team/agents/dev-division/SKILL.md
~/.claude/skills/agent-team/agents/leadership-division/SKILL.md
~/.claude/skills/agent-team/agents/management/SKILL.md
~/.claude/skills/agent-team/agents/pm/SKILL.md
~/.claude/skills/agent-team/agents/planner/SKILL.md
~/.claude/skills/agent-team/agents/coder/SKILL.md
~/.claude/skills/agent-team/agents/tester/SKILL.md
~/.claude/skills/agent-team/agents/pr-creator/SKILL.md
```

（Ops/Business Division は Plan 3/4 で追加）

- [ ] **Step 3: PM Agent の行数を確認する**

```bash
wc -l ~/.claude/skills/agent-team/agents/pm/SKILL.md
wc -l ~/.claude/skills/agent-team/agents/management/SKILL.md
```

Expected: それぞれ 100行以上 / 70行以上

---

## 完了チェックリスト

- [ ] `skills/agent-team/agents/pm/SKILL.md` が作成されている
- [ ] `skills/agent-team/agents/management/SKILL.md` が作成されている
- [ ] `skills/agent-team/agents/leadership-division/SKILL.md` が作成されている
- [ ] `skills/agent-team/SKILL.md` に `_run leadership` が追加されている
- [ ] `start` コマンドに Leadership の CronJob（日次）が追加されている
- [ ] `~/.claude/skills/agent-team/` にグローバルインストール済み

---

## 次のステップ

Plan 5 完了後、残りの Plan 3（Ops Division）と Plan 4（Business Division）に進む。
Plan 3 では以下を実装する：
- Monitor Agent（エラー・メトリクス監視）
- Incident Agent（障害調査・修正指示）
- Perf Agent（ボトルネック分析）
- Ops Division orchestrator
