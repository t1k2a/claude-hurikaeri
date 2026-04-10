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

"agent-task" ラベルの Issue がない場合、ラベルなしで最新の open Issue を1件取得する：
```bash
command -v gh >/dev/null 2>&1 && \
  gh issue list --state open --limit 1 --json number,title,body \
  || echo "gh not available"
```

gh が利用できない、または open Issue が0件の場合は「処理対象の Issue が見つかりません。終了します。」と出力して終了する。

Issue が見つかった場合、Issue 番号とタイトルをメモしておく。

## Step 2: Planner Agent を呼ぶ（リトライ最大3回）

`~/.claude/skills/agent-team/agents/planner/SKILL.md` の内容を Read ツールで読む。

そのプロンプト内容に Issue 番号を $ARGUMENTS として付加し、Agent tool でサブエージェントを起動する：
- subagent_type: general-purpose
- prompt: [planner/SKILL.md の内容] + "\n\n$ARGUMENTS: [Issue番号]"

Planner の出力（実装設計書テキスト）をメモしておく。

Planner が失敗した場合（出力がない、エラーのみ）：
- 最大3回リトライする
- 3回失敗したら以下を実行して終了する：
  ```bash
  gh issue edit [Issue番号] --add-label "needs-human" 2>/dev/null || true
  ```
  「Planner が3回失敗しました。Issue #[番号] に needs-human ラベルを付けました。」と出力して終了。

## Step 3: Coder Agent を呼ぶ（リトライ最大3回）

`~/.claude/skills/agent-team/agents/coder/SKILL.md` の内容を Read ツールで読む。

Step 2 の設計書テキストを $ARGUMENTS として付加し、Agent tool でサブエージェントを起動する：
- subagent_type: general-purpose
- prompt: [coder/SKILL.md の内容] + "\n\n$ARGUMENTS: [設計書テキスト]"

Coder の出力から以下を確認する：
- `### ブランチ名` セクションの値 → ブランチ名としてメモ
- `### ステータス` セクションの値
  - `DONE` → Step 4 へ進む
  - `BLOCKED:` で始まる → needs-human ラベルを付けて終了
    ```bash
    gh issue edit [Issue番号] --add-label "needs-human" 2>/dev/null || true
    ```

Coder が失敗（出力なし）の場合：最大3回リトライ、3回失敗で needs-human ラベル付与して終了。

## Step 4: Tester Agent を呼ぶ

`~/.claude/skills/agent-team/agents/tester/SKILL.md` の内容を Read ツールで読む。

Step 3 で取得したブランチ名を $ARGUMENTS として付加し、Agent tool でサブエージェントを起動する：
- subagent_type: general-purpose
- prompt: [tester/SKILL.md の内容] + "\n\n$ARGUMENTS: [ブランチ名]"

Tester の出力の `### テスト結果` セクションを確認する：
- `PASS` → Step 5 へ進む
- `NO_TEST` → Step 5 へ進む（PR 本文に NO_TEST である旨が含まれる）
- `FAIL` → 以下を実行して終了する：
  ```bash
  gh issue edit [Issue番号] --add-label "needs-human" 2>/dev/null || true
  ```
  「テストが失敗しました。Issue #[番号] に needs-human ラベルを付けました。」と出力して終了。

## Step 5: PR Creator Agent を呼ぶ

`~/.claude/skills/agent-team/agents/pr-creator/SKILL.md` の内容を Read ツールで読む。

ブランチ名と設計書テキストを `|` で区切って $ARGUMENTS として付加し、Agent tool でサブエージェントを起動する：
- subagent_type: general-purpose
- prompt: [pr-creator/SKILL.md の内容] + "\n\n$ARGUMENTS: [ブランチ名]|[設計書テキスト]"

## Step 6: 完了を報告する

```
Dev Division 完了報告:
- Issue: #[Issue番号] [タイトル]
- ブランチ: [ブランチ名]
- テスト: [PASS / NO_TEST]
- PR: [PR URL または "MANUAL_REQUIRED"]
```
