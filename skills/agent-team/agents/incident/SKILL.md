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
- **コードバグ系**: テスト失敗、例外/エラーが出ている、revert コミットがある → Step 3a
- **パフォーマンス系**: CPU/メモリ高負荷、処理が遅い → Step 3b
- **インフラ系**: ポートが LISTEN していない、プロセスが落ちている → Step 3c

## Step 2: 根本原因を調査する

```bash
git log --oneline --since="2 hours ago" --name-only 2>/dev/null | head -30
grep -r "<エラーメッセージのキーワード>" --include="*.js" --include="*.ts" --include="*.py" \
  --include="*.go" -l 2>/dev/null | head -5
```

Read ツールで該当ファイルの問題箇所を確認し、修正方針を決める。

## Step 3a: コードバグ系 → Coder Agent に修正依頼

`~/.claude/skills/agent-team/agents/coder/SKILL.md` を Read ツールで読む。

以下の形式の設計書を作成し、$ARGUMENTS として Coder Agent に渡す：

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

Agent tool で Coder Agent を起動する：
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
Coder Agent に修正を依頼しました。ブランチ: fix/incident-<日時>
```

**パフォーマンス系:**
```
## Incident Agent 完了報告

### ALERT 種別
パフォーマンス

### 対応
Perf Agent に分析を依頼しました。
```

**インフラ系:**
```
## Incident Agent 完了報告

### ALERT 種別
インフラ（手動対応必要）

### 対応
GitHub Issue を作成しました: <Issue URL>
```
