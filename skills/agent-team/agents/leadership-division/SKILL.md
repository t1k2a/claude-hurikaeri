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
- prompt: Read ツールで読んだ pm/SKILL.md の内容全文を先頭に置き、末尾に以下を追記する：
  ```
  $ARGUMENTS: report
  ```

PM Agent の出力（`## PM デイリーレポート` 以降の全文）を保持する。

PM Agent が失敗した場合（出力が `## PM デイリーレポート` を含まない）：
「PM Agent が失敗しました。Leadership Division を終了します。」と出力して終了する。

## Step 2: 経営 Agent を呼ぶ

`~/.claude/skills/agent-team/agents/management/SKILL.md` を Read ツールで読む。

Step 1 の PM レポートテキストを $ARGUMENTS として付加し、Agent tool で起動する：
- subagent_type: general-purpose
- prompt: Read ツールで読んだ management/SKILL.md の内容全文を先頭に置き、末尾に以下を追記する：
  ```
  $ARGUMENTS: [Step 1 の PM レポートテキスト全文]
  ```

経営 Agent の出力（`## 経営レスポンス` 以降の全文）を保持する。

経営 Agent が失敗した場合（出力が `## 経営レスポンス` を含まない）：
「経営 Agent が失敗しました。PM レポートのみで終了します。」と出力して終了する。

## Step 3: PM Agent を呼ぶ（post_report モード）

`~/.claude/skills/agent-team/agents/pm/SKILL.md` を Read ツールで読む。

Step 2 の経営 Agent の返答を `post_report ` プレフィックス付きで付加し、Agent tool で起動する：
- subagent_type: general-purpose
- prompt: Read ツールで読んだ pm/SKILL.md の内容全文を先頭に置き、末尾に以下を追記する：
  ```
  $ARGUMENTS: post_report [Step 2 の経営 Agent 返答テキスト全文]
  ```

## Step 4: 完了を報告する

```
Leadership Division 完了報告:
- PM レポート: 生成済み
- 経営レスポンス: 生成済み
- Issue 化: PM Agent が実施
- leadership-log.md: 更新済み
```
