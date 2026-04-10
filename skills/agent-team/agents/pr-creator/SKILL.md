---
name: agent-team-pr-creator
description: >
  Dev Division PR Creator. テスト通過後に PR を作成して説明文とチェックリストを付与する。
  Dev Division orchestrator から Agent tool で呼ばれる。
argument-hint: "<branch_name>|<設計書テキスト>"
---

# PR Creator Agent

$ARGUMENTS（ブランチ名と設計書テキストを `|` で区切ったもの）を受け取り、PR を作成する。

## Step 1: 引数を解析する

$ARGUMENTS を最初の `|` で分割する：
- 最初の部分: ブランチ名
- 残りの部分: 設計書テキスト

## Step 2: gh CLI の利用可否を確認する

```bash
command -v gh >/dev/null 2>&1 && echo "gh available" || echo "gh not available"
```

gh が利用できない場合は Step 4 の代替手順を実行する。

## Step 3: PR を作成する（gh CLI が利用できる場合）

リモートにプッシュする：
```bash
git push origin <ブランチ名> 2>&1
```

設計書から以下を抽出する：
- `### Issue` セクション → PR タイトル
- `### 概要` セクション → PR 本文の概要
- `### 対象ファイル` セクション → 変更内容
- `### 完了条件` セクション → チェックリスト

PR を作成する：
```bash
# ラベルが存在しない場合は作成する
gh label create "agent-created" --color "#0075ca" --force 2>/dev/null || true
```

```bash
gh pr create \
  --title "<### Issue から取得したタイトル>" \
  --body "## 概要

<設計書の ### 概要 の内容>

## 変更内容

<設計書の ### 対象ファイル の内容>

## テスト

- [x] 自動テスト通過済み
- [ ] 人間によるコードレビュー

## 完了条件

<設計書の ### 完了条件 の内容>

---
🤖 このPRは Agent Team によって自動作成されました" \
  --label "agent-created" \
  --head <ブランチ名>
```

## Step 4: 代替手順（gh CLI が利用できない場合）

以下を出力する：

```
## PR 作成情報（手動で PR を作成してください）

### ブランチ名
<ブランチ名>

### タイトル
<設計書から取得したタイトル>

### 本文
## 概要
<設計書の概要>

## 変更内容
<設計書の対象ファイル>

## 完了条件
<設計書の完了条件>
```

## Step 5: 結果を出力する

gh CLI で PR 作成に成功した場合：
```
## PR Creator 完了報告

### PR URL
<gh pr create の出力URL>

### ステータス
DONE
```

手動作成が必要な場合：
```
## PR Creator 完了報告

### ステータス
MANUAL_REQUIRED: gh CLI が利用できないため、上記の情報を使って手動でPRを作成してください。
```
