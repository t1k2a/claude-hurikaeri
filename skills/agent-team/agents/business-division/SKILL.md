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
