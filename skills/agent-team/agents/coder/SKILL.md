---
name: agent-team-coder
description: >
  Dev Division Coder. Planner の設計書を受け取り、コードを実装してブランチにコミットする。
  Dev Division orchestrator から Agent tool で呼ばれる。
argument-hint: "<設計書テキスト>"
---

# Coder Agent

$ARGUMENTS（Planner が生成した実装設計書）を受け取り、コードを実装する。

## Step 1: 現在のリポジトリを確認する

```bash
git rev-parse --show-toplevel
git branch --show-current
git status
```

## Step 2: 設計書からブランチ名を取得する

$ARGUMENTS 内の「### ブランチ名」セクションからブランチ名を読み取る：
```bash
# 設計書テキストを一時ファイルに保存してから抽出する
echo "$ARGUMENTS_TEXT" | grep -A1 "### ブランチ名" | tail -1 | tr -d ' '
```
抽出できない場合は `feature/agent-auto-$(date +%Y%m%d-%H%M%S)` を使用する。

## Step 3: feature ブランチを作成する

現在のブランチが main または master の場合のみ新しいブランチを作成する：
```bash
git checkout -b <ブランチ名>
```

すでに feature ブランチにいる場合はそのまま続ける。

## Step 4: 設計書に従ってコードを実装する

$ARGUMENTS の「### 実装手順」セクションに従って実装する。

各ファイルの変更は以下のツールで行う：
- 既存ファイルの変更: Edit ツール
- 新規ファイル作成: Write ツール
- コマンド実行が必要な場合: Bash ツール

**重要な制約:**
- 設計書に書かれていない変更は行わない（YAGNI）
- すべての変更をまとめて1回でコミットする
- セキュリティ上の問題（SQLインジェクション、XSSなど）が設計にある場合は実装を中断し、以下の形式で報告する：
  ```
  ## Coder 完了報告

  ### ステータス
  BLOCKED: セキュリティ上の問題を検出 — <問題の説明>
  ```

## Step 5: 変更をコミットする

```bash
# 設計書の「### 対象ファイル」に列挙されたファイルのみを add する
# （意図しないファイル .env 等の混入を防ぐため git add -A は使わない）
git add <設計書の ### 対象ファイル に列挙されたパス>
git status  # add された内容を確認する
git commit -m "feat: <Issue のタイトルまたは概要の短縮版>"
```

## Step 6: 結果を出力する

```
## Coder 完了報告

### ブランチ名
<作成したブランチ名>

### 実装内容
<変更したファイルと内容の概要>

### コミット
<コミットハッシュ>: <コミットメッセージ>

### ステータス
DONE
```

実装できなかった場合：
```
## Coder 完了報告

### ステータス
BLOCKED: <理由>
```
