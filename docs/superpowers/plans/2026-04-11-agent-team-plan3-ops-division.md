# 自律エージェントチーム - Plan 3: Ops Division Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 15分ごとにログ・メトリクスを監視し、異常検知時に Incident Agent が原因を調査して Coder（修正）または Perf（最適化）へ自動エスカレーションする Ops Division を構築する。

**Architecture:** Ops Division orchestrator が Monitor Agent を呼び、ALERT の場合のみ Incident Agent をスポーンする。Incident Agent が根本原因を判断し、コード修正が必要なら Coder Agent を、パフォーマンス改善なら Perf Agent を起動する。失敗時はサイレントにログを記録してサービスを止めない。

**Tech Stack:** Claude Code (superpowers), SKILL.md files, Agent tool, git, Bash（ログ確認・プロセス確認）

> **前提:** Plan 1（Foundation）と Plan 2（Dev Division）が完了していること。Coder Agent（`~/.claude/skills/agent-team/agents/coder/SKILL.md`）が存在すること。

---

## File Structure

| ファイル | 役割 |
|---------|------|
| `skills/agent-team/agents/ops-division/SKILL.md` | Ops Division orchestrator |
| `skills/agent-team/agents/monitor/SKILL.md` | Monitor Agent — ログ・エラー・メトリクス確認 |
| `skills/agent-team/agents/incident/SKILL.md` | Incident Agent — 根本原因調査・Coder/Perf への指示 |
| `skills/agent-team/agents/perf/SKILL.md` | Perf Agent — ボトルネック分析・最適化提案 |
| `skills/agent-team/SKILL.md` | `_run ops` セクションを更新（PLACEHOLDER → 実際の呼び出し） |

---

### Task 1: Monitor Agent を実装する

**Files:**
- Create: `skills/agent-team/agents/monitor/SKILL.md`

- [ ] **Step 1: ディレクトリを作成する**

```bash
mkdir -p /home/joji/claude-hurikaeri/skills/agent-team/agents/monitor
```

- [ ] **Step 2: SKILL.md を以下の内容で作成する**

`/home/joji/claude-hurikaeri/skills/agent-team/agents/monitor/SKILL.md`:

```markdown
---
name: agent-team-monitor
description: >
  Ops Division Monitor. ログ・エラー・メトリクスを確認し、
  異常があれば ALERT を、正常なら CLEAN を報告する。
  Ops Division orchestrator から Agent tool で呼ばれる。
---

# Monitor Agent

ログ・git 履歴・エラーファイルを確認して異常を検知する。

## Step 1: git の直近コミットとエラーパターンを確認する

```bash
# 直近のコミット（1時間以内）
git log --oneline --since="1 hour ago" --no-merges 2>/dev/null | head -10

# テストが壊れているか確認（テストコマンド自動検出）
if [ -f package.json ]; then
  npm test 2>&1 | tail -10
elif [ -f pytest.ini ] || [ -f pyproject.toml ]; then
  pytest -q 2>&1 | tail -10
elif [ -f go.mod ]; then
  go test ./... 2>&1 | tail -10
fi
```

## Step 2: エラーログファイルを確認する

一般的なエラーログの場所を確認する：
```bash
# Node.js プロジェクト
[ -f npm-debug.log ] && cat npm-debug.log | tail -20

# 一般的なログディレクトリ
[ -d logs ] && ls -lt logs/ | head -5
[ -d log ] && ls -lt log/ | head -5
[ -f error.log ] && tail -20 error.log
[ -f app.log ] && grep -i "error\|exception\|fatal" app.log 2>/dev/null | tail -10
```

## Step 3: プロセス・リソースを確認する（サービス稼働中の場合）

```bash
# CPU/メモリ使用率の確認
top -bn1 2>/dev/null | head -5 || ps aux --sort=-%cpu 2>/dev/null | head -5

# ポートが LISTEN 状態か確認（Node.js 等のサーバー）
ss -tlnp 2>/dev/null | grep -E "3000|8080|8000" | head -5
```

## Step 4: 異常判定と報告

以下の条件のいずれかに該当する場合は ALERT を報告する：
- テストが失敗している（exit code != 0）
- エラーログに "error", "exception", "fatal" が含まれる
- エラーログファイルが存在し、サイズが 0 より大きい
- 直近1時間のコミットに "fix:", "hotfix:", "revert:" が含まれる（既知の問題の修正が入った可能性）

**CLEAN の場合:**
```
## Monitor 報告

### ステータス
CLEAN

### 確認内容
- テスト: PASS（または未検出）
- エラーログ: なし
- 確認時刻: <ISO8601 日時>
```

**ALERT の場合:**
```
## Monitor 報告

### ステータス
ALERT

### 検知した問題
<問題の詳細（テスト失敗の内容、エラーログの内容など）>

### 根拠
<どのコマンドで何を検知したか>

### 確認時刻
<ISO8601 日時>
```
```

- [ ] **Step 3: 確認**

```bash
head -10 /home/joji/claude-hurikaeri/skills/agent-team/agents/monitor/SKILL.md
```

- [ ] **Step 4: Commit**

```bash
git -C /home/joji/claude-hurikaeri add skills/agent-team/agents/monitor/
git -C /home/joji/claude-hurikaeri commit -m "feat: monitor agent SKILL.md"
```

---

### Task 2: Perf Agent を実装する

**Files:**
- Create: `skills/agent-team/agents/perf/SKILL.md`

- [ ] **Step 1: ディレクトリを作成する**

```bash
mkdir -p /home/joji/claude-hurikaeri/skills/agent-team/agents/perf
```

- [ ] **Step 2: SKILL.md を以下の内容で作成する**

`/home/joji/claude-hurikaeri/skills/agent-team/agents/perf/SKILL.md`:

```markdown
---
name: agent-team-perf
description: >
  Ops Division Perf Agent. ボトルネックを分析して最適化提案を行い、
  必要に応じて GitHub Issue を作成する。
  Incident Agent から Agent tool で呼ばれる。
argument-hint: "<Monitor の ALERT 内容>"
---

# Perf Agent

$ARGUMENTS（Monitor の ALERT 内容）を受け取り、パフォーマンス観点で分析する。

## Step 1: 問題の種類を判断する

$ARGUMENTS を確認し、以下のどれに該当するか判断する：
- CPU/メモリ使用率が高い → リソース使用量の最適化
- レスポンスが遅い → クエリ・処理の最適化
- ループ・再帰が非効率 → アルゴリズムの改善
- 不要なファイル I/O → キャッシュ・バッファリングの追加

## Step 2: 対象コードを確認する

$ARGUMENTS に言及されたファイルや該当箇所を Read ツールで確認する：
```bash
git log --oneline --since="48 hours ago" --name-only 2>/dev/null | head -30
```

直近の変更ファイルと ALERT 内容を照合し、ボトルネックの原因を特定する。

## Step 3: 最適化提案をまとめる

以下の形式で提案を生成する：

```
## Perf Agent 分析結果

### 問題の概要
<何が遅い/重いか>

### 根本原因
<コードの何が問題か>

### 最適化提案
1. <具体的な変更案1>（対象: `ファイルパス:行番号`）
2. <具体的な変更案2>（対象: `ファイルパス:行番号`）

### 優先度
<高 / 中 / 低 + 理由>
```

## Step 4: GitHub Issue を作成する（優先度が高または中の場合）

```bash
gh issue create \
  --title "perf: <問題の概要>" \
  --body "<Step 3 の分析結果全文>" \
  --label "agent-task,performance" 2>/dev/null || echo "gh not available - Issue 化をスキップ"
```

gh が利用できない場合は分析結果のみを出力する。

## Step 5: 結果を出力する

```
## Perf Agent 完了報告

### 分析結果
<Step 3 の内容>

### Issue
<作成した Issue URL または "gh not available">

### ステータス
DONE
```
```

- [ ] **Step 3: 確認**

```bash
head -10 /home/joji/claude-hurikaeri/skills/agent-team/agents/perf/SKILL.md
```

- [ ] **Step 4: Commit**

```bash
git -C /home/joji/claude-hurikaeri add skills/agent-team/agents/perf/
git -C /home/joji/claude-hurikaeri commit -m "feat: perf agent SKILL.md"
```

---

### Task 3: Incident Agent を実装する

**Files:**
- Create: `skills/agent-team/agents/incident/SKILL.md`

- [ ] **Step 1: ディレクトリを作成する**

```bash
mkdir -p /home/joji/claude-hurikaeri/skills/agent-team/agents/incident
```

- [ ] **Step 2: SKILL.md を以下の内容で作成する**

`/home/joji/claude-hurikaeri/skills/agent-team/agents/incident/SKILL.md`:

```markdown
---
name: agent-team-incident
description: >
  Ops Division Incident Agent. Monitor の ALERT を受け取り根本原因を調査し、
  コード修正が必要なら Coder Agent を、パフォーマンス改善なら Perf Agent を起動する。
  Ops Division orchestrator から Agent tool で呼ばれる。
argument-hint: "<Monitor の ALERT 内容>"
---

# Incident Agent

$ARGUMENTS（Monitor の ALERT 内容）を受け取り、根本原因を調査してエスカレーションする。

## Step 1: ALERT の種類を分類する

$ARGUMENTS を確認し、問題の種類を判断する：

- **コードバグ系**: テスト失敗、例外/エラーが出ている、revert コミットがある
  → Coder Agent にエスカレーション
- **パフォーマンス系**: CPU/メモリ高負荷、処理が遅い
  → Perf Agent にエスカレーション
- **インフラ系**: ポートが LISTEN していない、プロセスが落ちている
  → GitHub Issue 化（自動修正対象外）

## Step 2: 根本原因を調査する

ALERT に言及されたファイル・エラーメッセージを追跡する：

```bash
# エラーに関連するファイルの直近変更を確認
git log --oneline --since="2 hours ago" --name-only 2>/dev/null | head -30

# エラーメッセージに関連するコードを検索
grep -r "<エラーメッセージのキーワード>" --include="*.js" --include="*.ts" --include="*.py" \
  --include="*.go" -l 2>/dev/null | head -5
```

Read ツールで該当ファイルの問題箇所を確認し、修正方針を決める。

## Step 3a: コードバグ系 → Coder Agent に修正依頼

`~/.claude/skills/agent-team/agents/coder/SKILL.md` を Read ツールで読む。

以下の形式の設計書を作成し、Coder Agent に渡す：

```
## 実装設計書

### Issue
バグ修正: <エラーの概要>

### 概要
<何が起きているか>。<根本原因>。<何を修正するか>。

### 対象ファイル
- 変更: `<ファイルパス>` — <修正内容>

### 実装手順
1. <具体的な修正手順1>
2. <具体的な修正手順2>

### ブランチ名
fix/incident-<YYYYMMDD-HHMM>

### 完了条件
- [ ] エラーが再現しなくなる
- [ ] テストがすべて通る
```

作成した設計書を $ARGUMENTS として Agent tool で Coder Agent を起動する：
- subagent_type: general-purpose
- prompt: [coder/SKILL.md の内容] + "\n\n$ARGUMENTS: [上記設計書]"

## Step 3b: パフォーマンス系 → Perf Agent に分析依頼

`~/.claude/skills/agent-team/agents/perf/SKILL.md` を Read ツールで読む。

Monitor の ALERT 内容を $ARGUMENTS として Agent tool で Perf Agent を起動する：
- subagent_type: general-purpose
- prompt: [perf/SKILL.md の内容] + "\n\n$ARGUMENTS: [ALERT 内容]"

## Step 3c: インフラ系 → GitHub Issue を作成して終了

```bash
gh issue create \
  --title "ops: インフラ異常検知 — <概要>" \
  --body "## 検知内容\n\n<Monitor の ALERT 内容>\n\n## 調査メモ\n\n<Step 2 の調査結果>\n\n## 対応\n手動対応が必要です。" \
  --label "needs-human,ops" 2>/dev/null || echo "gh not available"
```

## Step 4: 完了を報告する

**コードバグ系:**
```
## Incident Agent 完了報告

### ALERT 種別
コードバグ

### 根本原因
<調査結果>

### 対応
Coder Agent に修正を依頼しました。
ブランチ: fix/incident-<日時>
```

**パフォーマンス系:**
```
## Incident Agent 完了報告

### ALERT 種別
パフォーマンス

### 根本原因
<調査結果>

### 対応
Perf Agent に分析を依頼しました。
```

**インフラ系:**
```
## Incident Agent 完了報告

### ALERT 種別
インフラ（手動対応必要）

### 根本原因
<調査結果>

### 対応
GitHub Issue を作成しました: <Issue URL>
```
```

- [ ] **Step 3: 確認**

```bash
wc -l /home/joji/claude-hurikaeri/skills/agent-team/agents/incident/SKILL.md
```

Expected: 90行以上

- [ ] **Step 4: Commit**

```bash
git -C /home/joji/claude-hurikaeri add skills/agent-team/agents/incident/
git -C /home/joji/claude-hurikaeri commit -m "feat: incident agent SKILL.md"
```

---

### Task 4: Ops Division orchestrator を実装する

**Files:**
- Create: `skills/agent-team/agents/ops-division/SKILL.md`

- [ ] **Step 1: ディレクトリを作成する**

```bash
mkdir -p /home/joji/claude-hurikaeri/skills/agent-team/agents/ops-division
```

- [ ] **Step 2: SKILL.md を以下の内容で作成する**

`/home/joji/claude-hurikaeri/skills/agent-team/agents/ops-division/SKILL.md`:

```markdown
---
name: agent-team-ops
description: >
  Ops Division orchestrator. Monitor → (ALERT時のみ) Incident の順で実行する。
  失敗はサイレントにログ記録してサービスを止めない。
  Chief Orchestrator から Agent tool で呼ばれる。
---

# Ops Division

## Step 1: Monitor Agent を呼ぶ

`~/.claude/skills/agent-team/agents/monitor/SKILL.md` を Read ツールで読む。

そのプロンプトで Agent tool を起動する：
- subagent_type: general-purpose
- prompt: [monitor/SKILL.md の内容]

Monitor の出力から `### ステータス` セクションの値を確認する：
- `CLEAN` → Step 3（ログ記録のみ）へ進む
- `ALERT` → Step 2 へ進む

Monitor が失敗した場合（出力なし）：
「Monitor Agent が失敗しました。Ops サイクルをスキップします。」と出力して終了する。
（サービスを止めないためリトライは行わない）

## Step 2: Incident Agent を呼ぶ（ALERT の場合のみ）

`~/.claude/skills/agent-team/agents/incident/SKILL.md` を Read ツールで読む。

Monitor の ALERT 内容を $ARGUMENTS として付加し、Agent tool で起動する：
- subagent_type: general-purpose
- prompt: [incident/SKILL.md の内容] + "\n\n$ARGUMENTS: [Monitor の ALERT 内容]"

Incident Agent が失敗した場合：
「Incident Agent が失敗しました。Monitor の ALERT をログに記録します。」と出力して続行する。

## Step 3: 完了を報告する

CLEAN の場合：
```
Ops Division 完了報告:
- Monitor: CLEAN
- 確認時刻: <ISO8601 日時>
- 対応: なし
```

ALERT の場合：
```
Ops Division 完了報告:
- Monitor: ALERT
- Incident: 対応完了（詳細は上記）
- 確認時刻: <ISO8601 日時>
```
```

- [ ] **Step 3: 確認**

```bash
wc -l /home/joji/claude-hurikaeri/skills/agent-team/agents/ops-division/SKILL.md
```

Expected: 50行以上

- [ ] **Step 4: Commit**

```bash
git -C /home/joji/claude-hurikaeri add skills/agent-team/agents/ops-division/
git -C /home/joji/claude-hurikaeri commit -m "feat: ops-division orchestrator SKILL.md (Monitor→Incident)"
```

---

### Task 5: Chief Orchestrator の `_run ops` を更新する

**Files:**
- Modify: `skills/agent-team/SKILL.md`

- [ ] **Step 1: 現在の `_run ops` セクションを確認する**

```bash
grep -n "PLACEHOLDER\|_run ops\|Ops Division" /home/joji/claude-hurikaeri/skills/agent-team/SKILL.md
```

- [ ] **Step 2: `_run ops` セクションを更新する**

Read ツールで `skills/agent-team/SKILL.md` を読み、以下の部分を Edit ツールで置き換える。

現在の内容：
```
### _run ops（Ops Division を実行）

Ops Division のエージェントは Plan 3 で実装する。
現時点では以下を出力して終了：
```
[Ops Division] PLACEHOLDER - Plan 3 で実装予定
```
```

置き換え後：
```
### _run ops（Ops Division を実行）

起動時チェックを通過後、以下を実行する：

1. `~/.claude/skills/agent-team/agents/ops-division/SKILL.md` を Read ツールで読む。
2. そのプロンプト内容で Agent tool を起動する（subagent_type: general-purpose）。
3. Ops Division からの完了報告を出力する。
```

- [ ] **Step 3: Commit**

```bash
git -C /home/joji/claude-hurikaeri add skills/agent-team/SKILL.md
git -C /home/joji/claude-hurikaeri commit -m "feat: _run ops を ops-division orchestrator の実際の呼び出しに更新"
```

---

### Task 6: グローバルインストールを更新して確認する

- [ ] **Step 1: グローバルインストールを更新する**

```bash
cp -r /home/joji/claude-hurikaeri/skills/agent-team/. ~/.claude/skills/agent-team/
```

- [ ] **Step 2: ファイル構造を確認する**

```bash
find ~/.claude/skills/agent-team -name "SKILL.md" | sort
```

Expected（Plan 2 の6ファイル + 4ファイル = 10ファイル）:
```
~/.claude/skills/agent-team/SKILL.md
~/.claude/skills/agent-team/agents/coder/SKILL.md
~/.claude/skills/agent-team/agents/dev-division/SKILL.md
~/.claude/skills/agent-team/agents/incident/SKILL.md
~/.claude/skills/agent-team/agents/monitor/SKILL.md
~/.claude/skills/agent-team/agents/ops-division/SKILL.md
~/.claude/skills/agent-team/agents/perf/SKILL.md
~/.claude/skills/agent-team/agents/planner/SKILL.md
~/.claude/skills/agent-team/agents/pr-creator/SKILL.md
~/.claude/skills/agent-team/agents/tester/SKILL.md
```

- [ ] **Step 3: _run ops が PLACEHOLDER でないことを確認する**

```bash
grep "PLACEHOLDER\|ops-division" ~/.claude/skills/agent-team/SKILL.md | grep "_run ops" -A3
```

Expected: PLACEHOLDER の行が消えて `ops-division/SKILL.md` の Read が記述されている

---

## 完了チェックリスト

- [ ] `skills/agent-team/agents/monitor/SKILL.md` が作成されている
- [ ] `skills/agent-team/agents/perf/SKILL.md` が作成されている
- [ ] `skills/agent-team/agents/incident/SKILL.md` が作成されている（Coder/Perf への分岐含む）
- [ ] `skills/agent-team/agents/ops-division/SKILL.md` が作成されている
- [ ] `skills/agent-team/SKILL.md` の `_run ops` が更新されている
- [ ] `~/.claude/skills/agent-team/` にグローバルインストール済み

---

## 次のステップ

Plan 3 完了後、Plan 4（Business Division）または Plan 5（Leadership Division）に進む。
Plan 4 では以下を実装する：
- Researcher Agent（競合調査・拡散チャネル調査）
- Analyst Agent（GitHub統計・成長指標分析）
- Marketer Agent（告知文・SNS投稿生成）
- Business Division orchestrator
