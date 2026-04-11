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
- prompt: Read ツールで読んだ incident/SKILL.md の内容全文を先頭に置き、末尾に以下を追記する：
  ```
  $ARGUMENTS: [Monitor の ALERT 内容（### 検知した問題 以降の全文）]
  ```

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
