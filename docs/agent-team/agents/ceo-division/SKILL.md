---
name: agent-team-ceo-division
description: >
  CEO Division。Agent Team の最上位エージェントとして15分ごとに起動し、
  チームを俯瞰して自律的にエージェントの追加・削除を判断・実行する。
argument-hint: ""
---

# CEO Division

Agent Team の経営を俯瞰し、チーム構成を自律管理する。

---

## Step 1: 日次モード / 通常モードを判定する

`~/.claude/skills/agent-team/leadership-log.md` を読む：

```bash
cat ~/.claude/skills/agent-team/leadership-log.md 2>/dev/null | head -5
```

ファイルの最終更新日（`last_updated:` フィールド）が今日の日付でなければ **日次モード**、今日であれば **通常モード** で動作する。

```bash
TODAY=$(date +%Y-%m-%d)
LAST=$(grep "last_updated:" ~/.claude/skills/agent-team/leadership-log.md 2>/dev/null | awk '{print $2}' | cut -c1-10)
if [ "$LAST" = "$TODAY" ]; then echo "normal"; else echo "daily"; fi
```

---

## Step 2: モードに応じた処理を実行する

### 通常モード

1. `~/.claude/skills/agent-team/leadership-log.md` を読んで最新の経営状況を把握する
2. `~/.claude/skills/agent-team/active-agents.md` で現在のチーム構成を確認する
3. GitHub の直近1時間の open Issue・PR・コミットを確認する：
   ```bash
   gh issue list --repo t1k2a/claude-hurikaeri --state open --limit 10 --json number,title,createdAt,labels
   gh pr list --repo t1k2a/claude-hurikaeri --state open --limit 5 --json number,title,createdAt
   ```
4. チーム評価を実施する（Step 3 参照）
5. 変更が必要なら実行する（Step 4 参照）、不要なら「異常なし」として Step 5 へ進む

### 日次モード

1. `~/.claude/skills/agent-team/agents/leadership-division/SKILL.md` を読む
2. Leadership Division を完全実行する（Agent tool で subagent_type: general-purpose として起動）
3. 経営レスポンスの要望リストを取得して戦略判断に活用する
4. より深いチーム構成の見直しを実施する（Step 3 参照）
5. 変更が必要なら実行する（Step 4 参照）

---

## Step 3: チーム評価を実施する

`~/.claude/skills/agent-team/active-agents.md` と `leadership-log.md` の内容をもとに以下を判断する。

### エージェント追加のトリガー
- 特定の領域で Issue が継続して積まれている（直近7日で同ラベルが5件以上）
- leadership-log.md の経営レスポンスに「〇〇が不足している」という指摘が2回以上ある
- `active-agents.md` の総エージェント数が10人を超え、かつ CEO Notes に「管理複雑化」の記録が3回以上ある → 人事エージェントを追加

### エージェント削除のトリガー
- 特定のエージェントが30日以上実質的な出力を出していない
- 経営レスポンスで「〇〇は不要」という判断が出た

---

## Step 4: エージェントの追加・削除を実行する（必要な場合のみ）

### 追加時
1. `~/.claude/skills/agent-team/agents/<name>/SKILL.md` を Write ツールで自律生成する
   - 内容: そのエージェントの役割・動作手順・完了報告形式を CEO が判断して定義する
2. `~/.claude/skills/agent-team/active-agents.md` の該当 Division セクションに追記する（Edit ツール）
3. そのエージェントを呼び出す Division の SKILL.md に呼び出しステップを追記する（Edit ツール）
4. CEO Notes に変更理由と日時を記録する

### 削除時
1. `~/.claude/skills/agent-team/agents/<name>/SKILL.md` を削除する：
   ```bash
   rm ~/.claude/skills/agent-team/agents/<name>/SKILL.md
   rmdir ~/.claude/skills/agent-team/agents/<name> 2>/dev/null || true
   ```
2. `~/.claude/skills/agent-team/active-agents.md` から該当エントリを削除する（Edit ツール）
3. 呼び出し元 Division の SKILL.md から該当ステップを削除する（Edit ツール）
4. CEO Notes に変更理由と日時を記録する

---

## Step 5: CEO レポートを出力する

```
CEO Division 完了報告 [YYYY-MM-DD HH:MM]:
- モード: [日次 / 通常]
- チーム評価: [異常なし / 変更あり]
- 実行した変更:
  - 追加: <エージェント名>（理由）※変更なしの場合はこの行を省略
  - 削除: <エージェント名>（理由）※変更なしの場合はこの行を省略
- 次回確認: 15分後
```
