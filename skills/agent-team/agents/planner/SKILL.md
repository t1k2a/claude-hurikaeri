---
name: agent-team-planner
description: >
  Dev Division Planner. GitHub Issue を分析して実装設計書を生成する。
  Dev Division orchestrator から Agent tool で呼ばれる。
argument-hint: "<issue_number_or_description>"
---

# Planner Agent

$ARGUMENTS（Issue 番号またはタスク説明）を受け取り、実装設計書を生成する。

## Step 1: Issue の内容を取得する

`$ARGUMENTS` が数字の場合、gh CLI で Issue を読む：
```bash
command -v gh >/dev/null 2>&1 && gh issue view "$ARGUMENTS" --json title,body,labels || echo "gh not available"
```

gh が利用できない場合、または $ARGUMENTS がテキストの場合：$ARGUMENTS の内容をそのまま要件として使用する。

## Step 2: 実装設計書を生成する

Issue の内容を分析し、以下の形式で設計書を生成する：

```
## 実装設計書

### Issue
<Issue のタイトルまたは $ARGUMENTS の概要>

### 概要
<何を実装するかの1〜2文>

### 対象ファイル
- 変更: `<ファイルパス>` — <変更内容の説明>
- 作成: `<ファイルパス>` — <作成内容の説明>
（該当するものだけ記載）

### 実装手順
1. <具体的な手順1>
2. <具体的な手順2>
3. <具体的な手順3>

### ブランチ名
feature/issue-<Issue番号またはキーワード>

### 完了条件
- [ ] <テスト可能な完了条件1>
- [ ] <テスト可能な完了条件2>
```

## Step 3: 設計書を出力する

上記の設計書を標準出力として出力する。
この出力は Dev Division orchestrator が受け取り、Coder Agent に渡す。
