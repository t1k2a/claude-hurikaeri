# 自律エージェントチーム - Plan 2: Dev Division Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** GitHub Issue を受け取り、Planner → Coder → Tester → PR Creator の順に自律実行して PR を自動作成する Dev Division を構築する。

**Architecture:** Dev Division orchestrator（SKILL.md）が Agent tool で4つの専門エージェントを順次スポーンする。各エージェントは前のエージェントの出力をコンテキストとして受け取り、成果物を次のエージェントに渡す。失敗時は最大3回リトライし、3回失敗したら Issue に "needs-human" ラベルを付けてスキップする。

**Tech Stack:** Claude Code (superpowers), SKILL.md files, Agent tool, GitHub CLI (gh), git

> **前提:** Plan 1（Foundation）が完了していること。`/agent-team start` でオーケストレーターが稼働していること。

---

## File Structure

| ファイル | 役割 |
|---------|------|
| `skills/agent-team/agents/dev-division/SKILL.md` | Dev Division orchestrator（現在プレースホルダー → 今回実装） |
| `skills/agent-team/agents/planner/SKILL.md` | Issue → 実装設計書 |
| `skills/agent-team/agents/coder/SKILL.md` | 設計書 → コード実装 → ブランチコミット |
| `skills/agent-team/agents/tester/SKILL.md` | テスト実行 → pass/fail 判定 |
| `skills/agent-team/agents/pr-creator/SKILL.md` | PR 作成 → 説明文・チェックリスト付与 |
| `skills/agent-team/SKILL.md` | `_run dev` セクションを更新（PLACEHOLDER → 実際の呼び出し） |

---

### Task 1: Planner Agent を実装する

**Files:**
- Create: `skills/agent-team/agents/planner/SKILL.md`

- [ ] **Step 1: ディレクトリを作成する**

```bash
mkdir -p /home/joji/claude-hurikaeri/skills/agent-team/agents/planner
```

- [ ] **Step 2: SKILL.md を以下の内容で作成する**

`/home/joji/claude-hurikaeri/skills/agent-team/agents/planner/SKILL.md`:

```markdown
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
```

- [ ] **Step 3: 作成を確認する**

```bash
cat /home/joji/claude-hurikaeri/skills/agent-team/agents/planner/SKILL.md | head -15
```

Expected: frontmatter が表示される

- [ ] **Step 4: Commit**

```bash
git -C /home/joji/claude-hurikaeri add skills/agent-team/agents/planner/
git -C /home/joji/claude-hurikaeri commit -m "feat: planner agent SKILL.md"
```

---

### Task 2: Coder Agent を実装する

**Files:**
- Create: `skills/agent-team/agents/coder/SKILL.md`

- [ ] **Step 1: ディレクトリを作成する**

```bash
mkdir -p /home/joji/claude-hurikaeri/skills/agent-team/agents/coder
```

- [ ] **Step 2: SKILL.md を以下の内容で作成する**

`/home/joji/claude-hurikaeri/skills/agent-team/agents/coder/SKILL.md`:

```markdown
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

$ARGUMENTS 内の「### ブランチ名」セクションからブランチ名を読み取る。
見つからない場合は `feature/agent-auto-$(date +%Y%m%d-%H%M%S)` を使用する。

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
- 1ファイルずつ変更してコミットするのではなく、すべての変更をまとめて1回でコミットする
- セキュリティ上の問題（SQLインジェクション、XSSなど）が設計にある場合は実装を中断してコメントを残す

## Step 5: 変更をコミットする

```bash
git add -p  # 変更内容を確認してからステージング
git add <変更したファイルのパス>
git commit -m "feat: <Issue のタイトルまたは概要の短縮版>"
```

## Step 6: 結果を出力する

以下の形式で出力する：
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

実装できなかった場合（ファイルが見つからない、エラーが解決できないなど）：
```
## Coder 完了報告

### ステータス
BLOCKED: <理由>
```
```

- [ ] **Step 3: 確認**

```bash
head -15 /home/joji/claude-hurikaeri/skills/agent-team/agents/coder/SKILL.md
```

- [ ] **Step 4: Commit**

```bash
git -C /home/joji/claude-hurikaeri add skills/agent-team/agents/coder/
git -C /home/joji/claude-hurikaeri commit -m "feat: coder agent SKILL.md"
```

---

### Task 3: Tester Agent を実装する

**Files:**
- Create: `skills/agent-team/agents/tester/SKILL.md`

- [ ] **Step 1: ディレクトリを作成する**

```bash
mkdir -p /home/joji/claude-hurikaeri/skills/agent-team/agents/tester
```

- [ ] **Step 2: SKILL.md を以下の内容で作成する**

`/home/joji/claude-hurikaeri/skills/agent-team/agents/tester/SKILL.md`:

```markdown
---
name: agent-team-tester
description: >
  Dev Division Tester. Coder が実装したブランチのテストを実行して結果を報告する。
  Dev Division orchestrator から Agent tool で呼ばれる。
argument-hint: "<branch_name>"
---

# Tester Agent

$ARGUMENTS（テスト対象のブランチ名）を受け取り、テストを実行して結果を報告する。

## Step 1: ブランチを確認する

```bash
git branch --show-current
```

現在のブランチが $ARGUMENTS でない場合は切り替える：
```bash
git checkout "$ARGUMENTS"
```

## Step 2: テストコマンドを自動検出して実行する

以下の順で確認し、最初に見つかったコマンドを実行する：

```bash
# Node.js
if [ -f package.json ]; then
  cat package.json | grep -A5 '"scripts"' | grep '"test"'
fi

# Python
if [ -f pytest.ini ] || [ -f setup.py ] || [ -f pyproject.toml ]; then
  echo "pytest found"
fi

# Go
if [ -f go.mod ]; then
  echo "go test found"
fi
```

検出結果に応じて実行：
- `package.json` に `"test"` スクリプトがある場合: `npm test`
- `pytest` が利用可能な場合: `pytest -v 2>&1 | tail -30`
- `go.mod` がある場合: `go test ./... -v 2>&1 | tail -30`
- テストコマンドが見つからない場合: 「テストコマンドが見つかりません」と報告して PASS 扱いとする

## Step 3: 結果を報告する

テストが全部通った場合：
```
## Tester 完了報告

### ブランチ名
<$ARGUMENTS>

### テスト結果
PASS

### 詳細
<テスト実行の出力（最大20行）>
```

テストが失敗した場合：
```
## Tester 完了報告

### ブランチ名
<$ARGUMENTS>

### テスト結果
FAIL

### 失敗したテスト
<失敗したテストの名前と理由>

### 詳細
<テスト実行の出力（最大20行）>
```
```

- [ ] **Step 3: 確認**

```bash
head -15 /home/joji/claude-hurikaeri/skills/agent-team/agents/tester/SKILL.md
```

- [ ] **Step 4: Commit**

```bash
git -C /home/joji/claude-hurikaeri add skills/agent-team/agents/tester/
git -C /home/joji/claude-hurikaeri commit -m "feat: tester agent SKILL.md"
```

---

### Task 4: PR Creator Agent を実装する

**Files:**
- Create: `skills/agent-team/agents/pr-creator/SKILL.md`

- [ ] **Step 1: ディレクトリを作成する**

```bash
mkdir -p /home/joji/claude-hurikaeri/skills/agent-team/agents/pr-creator
```

- [ ] **Step 2: SKILL.md を以下の内容で作成する**

`/home/joji/claude-hurikaeri/skills/agent-team/agents/pr-creator/SKILL.md`:

```markdown
---
name: agent-team-pr-creator
description: >
  Dev Division PR Creator. テスト通過後に PR を作成して説明文とチェックリストを付与する。
  Dev Division orchestrator から Agent tool で呼ばれる。
argument-hint: "<branch_name> | <設計書テキスト>"
---

# PR Creator Agent

$ARGUMENTS（ブランチ名と設計書テキストを `|` で区切ったもの）を受け取り、PR を作成する。

## Step 1: 引数を解析する

$ARGUMENTS を `|` で分割する：
- 最初の部分: ブランチ名
- 残りの部分: 設計書テキスト

## Step 2: gh CLI の利用可否を確認する

```bash
command -v gh >/dev/null 2>&1 && echo "gh available" || echo "gh not available"
```

gh が利用できない場合は Step 4 の代替手順を実行する。

## Step 3: PR を作成する（gh CLI が利用できる場合）

現在のブランチがリモートにプッシュされているか確認する：
```bash
git push origin <ブランチ名> 2>&1 | tail -5
```

PR を作成する：
```bash
gh pr create \
  --title "<設計書の ### Issue セクションから取得したタイトル>" \
  --body "$(cat <<'EOF'
## 概要

<設計書の ### 概要 セクションの内容>

## 変更内容

<設計書の ### 対象ファイル セクションの内容>

## テスト

- [x] 自動テスト通過済み
- [ ] 人間によるコードレビュー

## 完了条件

<設計書の ### 完了条件 セクションの内容>

---
🤖 このPRは Agent Team によって自動作成されました
EOF
)" \
  --label "agent-created" \
  --head <ブランチ名>
```

## Step 4: 代替手順（gh CLI が利用できない場合）

PR 作成に必要な情報を出力する：

```
## PR 作成情報（手動で PR を作成してください）

### ブランチ名
<ブランチ名>

### タイトル
<設計書から取得したタイトル>

### 本文
（以下の内容で PR を作成してください）

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
```

- [ ] **Step 3: 確認**

```bash
head -15 /home/joji/claude-hurikaeri/skills/agent-team/agents/pr-creator/SKILL.md
```

- [ ] **Step 4: Commit**

```bash
git -C /home/joji/claude-hurikaeri add skills/agent-team/agents/pr-creator/
git -C /home/joji/claude-hurikaeri commit -m "feat: pr-creator agent SKILL.md"
```

---

### Task 5: Dev Division orchestrator を実装する

**Files:**
- Modify: `skills/agent-team/agents/dev-division/SKILL.md`（プレースホルダー → 実装）

- [ ] **Step 1: 現在のプレースホルダーを確認する**

```bash
cat /home/joji/claude-hurikaeri/skills/agent-team/agents/dev-division/SKILL.md
```

- [ ] **Step 2: SKILL.md を以下の内容で上書きする**

`/home/joji/claude-hurikaeri/skills/agent-team/agents/dev-division/SKILL.md`:

```markdown
---
name: agent-team-dev
description: >
  Dev Division orchestrator. GitHub の open Issue を1件取得し、
  Planner → Coder → Tester → PR Creator の順で自律実行する。
  Chief Orchestrator から Agent tool で呼ばれる。
---

# Dev Division

## Step 1: 処理対象の Issue を取得する

gh CLI で "agent-task" ラベルが付いた open Issue を1件取得する：
```bash
command -v gh >/dev/null 2>&1 && \
  gh issue list --label "agent-task" --state open --limit 1 --json number,title,body \
  || echo "gh not available"
```

gh が利用できない、または "agent-task" ラベルの Issue がない場合：
```bash
# ラベルなしで最新の open Issue を1件取得
command -v gh >/dev/null 2>&1 && \
  gh issue list --state open --limit 1 --json number,title,body \
  || echo "gh not available"
```

どちらも利用できない場合は「処理対象の Issue が見つかりません。終了します。」と出力して終了する。

Issue が見つかった場合、Issue 番号とタイトルを記録する。

## Step 2: Planner Agent を呼ぶ

Issue の番号を引数として Planner Agent を Agent tool で起動する：

```
Agent tool で以下を実行:
- subagent_type: general-purpose
- prompt: ~/.claude/skills/agent-team/agents/planner/SKILL.md の内容 + "\\n\\n$ARGUMENTS: <Issue番号>"
```

Planner の出力（実装設計書テキスト）を変数として保存する。

Planner が失敗した場合（出力がない、エラーメッセージのみ）：
- 最大3回リトライする
- 3回失敗したら Issue に "needs-human" ラベルを付けて終了する：
  ```bash
  gh issue edit <Issue番号> --add-label "needs-human" 2>/dev/null || true
  ```

## Step 3: Coder Agent を呼ぶ

Planner の設計書テキストを引数として Coder Agent を Agent tool で起動する：

```
Agent tool で以下を実行:
- subagent_type: general-purpose
- prompt: ~/.claude/skills/agent-team/agents/coder/SKILL.md の内容 + "\\n\\n$ARGUMENTS: <設計書テキスト>"
```

Coder の出力から「ブランチ名」と「ステータス」を抽出する。

Coder の出力に `BLOCKED:` が含まれる場合、または3回リトライしても失敗する場合：
```bash
gh issue edit <Issue番号> --add-label "needs-human" 2>/dev/null || true
```
終了する。

## Step 4: Tester Agent を呼ぶ

Coder が作成したブランチ名を引数として Tester Agent を Agent tool で起動する：

```
Agent tool で以下を実行:
- subagent_type: general-purpose
- prompt: ~/.claude/skills/agent-team/agents/tester/SKILL.md の内容 + "\\n\\n$ARGUMENTS: <ブランチ名>"
```

Tester の出力から「テスト結果（PASS/FAIL）」を確認する。

テスト結果が FAIL の場合：
```bash
gh issue edit <Issue番号> --add-label "needs-human" 2>/dev/null || true
```
「テストが失敗しました。Issue に needs-human ラベルを付けました。」と出力して終了する。

## Step 5: PR Creator Agent を呼ぶ（テスト PASS の場合のみ）

ブランチ名と設計書テキストを `|` で区切って PR Creator Agent を Agent tool で起動する：

```
Agent tool で以下を実行:
- subagent_type: general-purpose
- prompt: ~/.claude/skills/agent-team/agents/pr-creator/SKILL.md の内容 + "\\n\\n$ARGUMENTS: <ブランチ名>|<設計書テキスト>"
```

## Step 6: 完了を報告する

```
Dev Division 完了報告:
- Issue: #<Issue番号> <タイトル>
- ブランチ: <ブランチ名>
- テスト: PASS
- PR: <PR URL または "手動作成が必要">
```
```

- [ ] **Step 3: 確認**

```bash
wc -l /home/joji/claude-hurikaeri/skills/agent-team/agents/dev-division/SKILL.md
```

Expected: 80行以上

- [ ] **Step 4: Commit**

```bash
git -C /home/joji/claude-hurikaeri add skills/agent-team/agents/dev-division/
git -C /home/joji/claude-hurikaeri commit -m "feat: dev-division orchestrator SKILL.md (Planner→Coder→Tester→PR Creator)"
```

---

### Task 6: Chief Orchestrator の `_run dev` を更新する

**Files:**
- Modify: `skills/agent-team/SKILL.md`

現在 `_run dev` セクションには PLACEHOLDER が書かれている。これを実際の dev-division 呼び出しに更新する。

- [ ] **Step 1: 現在のファイルを確認する**

```bash
grep -n "PLACEHOLDER\|_run dev\|Dev Division" /home/joji/claude-hurikaeri/skills/agent-team/SKILL.md
```

- [ ] **Step 2: `_run dev` セクションを更新する**

Read ツールで `/home/joji/claude-hurikaeri/skills/agent-team/SKILL.md` を読み、以下のセクションを見つけて置き換える。

現在の内容（該当部分）：
```
### _run dev（Dev Division を実行）

Dev Division のエージェントは Plan 2 で実装する。
現時点では以下を出力して終了：
```
[Dev Division] PLACEHOLDER - Plan 2 で実装予定
```
```

置き換え後の内容：
```
### _run dev（Dev Division を実行）

起動時チェックを通過後、Dev Division orchestrator を Agent tool で呼ぶ：

`skills/agent-team/agents/dev-division/SKILL.md` の内容を読み、そのプロンプトで Agent tool を実行する。
サブエージェントタイプは general-purpose を使用する。

実行完了後、Dev Division からの完了報告を出力する。
```

- [ ] **Step 3: Commit**

```bash
git -C /home/joji/claude-hurikaeri add skills/agent-team/SKILL.md
git -C /home/joji/claude-hurikaeri commit -m "feat: _run dev を dev-division orchestrator の実際の呼び出しに更新"
```

---

### Task 7: グローバルインストールを更新してシナリオ検証する

**Files:**
- `~/.claude/skills/agent-team/` （グローバルインストール更新）

- [ ] **Step 1: グローバルインストールを更新する**

```bash
cp -r /home/joji/claude-hurikaeri/skills/agent-team/. ~/.claude/skills/agent-team/
```

- [ ] **Step 2: ファイル構造を確認する**

```bash
find ~/.claude/skills/agent-team -name "SKILL.md" | sort
```

Expected（6ファイル）:
```
/root/.claude/skills/agent-team/SKILL.md
/root/.claude/skills/agent-team/agents/dev-division/SKILL.md
/root/.claude/skills/agent-team/agents/planner/SKILL.md
/root/.claude/skills/agent-team/agents/coder/SKILL.md
/root/.claude/skills/agent-team/agents/tester/SKILL.md
/root/.claude/skills/agent-team/agents/pr-creator/SKILL.md
```

- [ ] **Step 3: Planner Agent の内容を確認する（手動シナリオテスト）**

Claude Code で以下を実行して Planner Agent が動作するか確認する：

```
以下のプロンプトで Planner Agent を手動テストしてください：
「README にバッジを追加したい。リポジトリ名は claude-hurikaeri、GitHub ユーザーは t1k2a です。」
```

Expected: 実装設計書が出力される（対象ファイル: README.md、ブランチ名が生成されている）

- [ ] **Step 4: 完了を記録する（コミット不要）**

手動テストの結果を確認してOKなら Task 7 完了とする。

---

## 完了チェックリスト

Plan 2 完了の条件：

- [ ] `skills/agent-team/agents/planner/SKILL.md` が作成されている
- [ ] `skills/agent-team/agents/coder/SKILL.md` が作成されている
- [ ] `skills/agent-team/agents/tester/SKILL.md` が作成されている
- [ ] `skills/agent-team/agents/pr-creator/SKILL.md` が作成されている
- [ ] `skills/agent-team/agents/dev-division/SKILL.md` がプレースホルダーから実装済みに更新されている
- [ ] `skills/agent-team/SKILL.md` の `_run dev` が PLACEHOLDER から実際の呼び出しに更新されている
- [ ] `~/.claude/skills/agent-team/` にグローバルインストール済み
- [ ] Planner Agent の手動テストが通過している

---

## 次のステップ

Plan 2 完了後、Plan 3（Ops Division）に進む。
Plan 3 では以下を実装する：
- Monitor Agent（エラー・メトリクス監視）
- Incident Agent（障害調査・修正指示）
- Perf Agent（ボトルネック分析・最適化提案）
- Ops Division orchestrator
