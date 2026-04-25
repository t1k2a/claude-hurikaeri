# CEO Agent 設計ドキュメント

**作成日:** 2026-04-24
**ステータス:** 承認済み

---

## 概要

Agent Team の最上位に CEO エージェントを追加する。CEO はチームの経営を俯瞰し、プロジェクトが多くのユーザーに届くよう戦略的に思考する。必要に応じてエージェントの追加・削除を自律的に実行し、人材管理が複雑になった場合は人事エージェントを追加する権限も持つ。

---

## アーキテクチャ

### 全体構造

```
CronJob (15分ごと: */15 * * * *)
  └─ /agent-team _run ceo
       │
       ├─ [判定] 今日初回か？
       │    ├─ YES → 日次モード（Leadership Division 完全実行 → 深い戦略判断）
       │    └─ NO  → 通常モード（軽量モニタリング → 即時判断）
       │
       ├─ active-agents.md を読んでチーム構成を確認
       ├─ チーム評価・判断
       └─ 必要なら追加/削除を実行 → CEO レポートを出力
```

### Cron 登録の変更

- 既存の `leadership` Cron（`57 8 * * *`）を廃止
- 新たに `ceo` Cron を `*/15 * * * *` で登録
- control.md の `cron_ids.leadership` → `cron_ids.ceo` に変更

---

## CEO Division の動作詳細

### 通常モード（15分ごと、日次モード以外）

1. `~/.claude/skills/agent-team/leadership-log.md` を読んで最新の経営状況を把握
2. `~/.claude/skills/agent-team/active-agents.md` で現在のチーム構成を確認
3. GitHub の open Issue/PR・最新コミットを軽く確認（直近1時間分）
4. チーム評価を実施（下記「判断基準」参照）
5. 変更が必要なら実行、不要なら「異常なし」で終了し CEO レポートを出力

### 日次モード（当日の初回起動時のみ）

判定方法: `leadership-log.md` の最終更新日が今日でなければ日次モードで実行。

1. Leadership Division を完全実行（PM → 経営 → PM(post_report)）
2. 経営レスポンスの要望リストを戦略判断に活用
3. より深いチーム構成の見直しを実施
4. `leadership-log.md` が更新されることで次回以降は通常モードになる

---

## チーム評価の判断基準

### エージェント追加のトリガー
- 特定の領域（例: セキュリティ、パフォーマンス）で Issue が継続して積まれている
- 経営レスポンスに「〇〇が不足している」という指摘が2回以上ある
- 人材管理が複雑化している（下記「人事エージェント追加条件」参照）

### エージェント削除のトリガー
- 特定のエージェントが30日以上実質的な出力を出していない
- 経営レスポンスで「〇〇は不要」という判断が出た場合

### 人事エージェント追加条件
以下のいずれかを満たした場合、CEO は人事エージェントを自律追加する：
- `active-agents.md` の総エージェント数が10人を超えた
- CEO Notes に「管理複雑化」の記録が3回以上ある

---

## エージェント追加・削除の仕組み

### 追加時
1. `~/.claude/skills/agent-team/agents/<name>/SKILL.md` を自律生成（内容はCEOが判断して作成）
2. `active-agents.md` の該当 Division に追記
3. そのエージェントを使う Division の SKILL.md に呼び出しステップを追記

### 削除時
1. `~/.claude/skills/agent-team/agents/<name>/SKILL.md` を削除
2. `active-agents.md` から除外
3. 呼び出し元 Division の SKILL.md からそのステップを削除

---

## active-agents.md の構造

場所: `~/.claude/skills/agent-team/active-agents.md`

```markdown
# Active Agents

last_updated: YYYY-MM-DDTHH:MM:SS

## Divisions
- dev-division
- ops-division
- business-division
- leadership-division
- ceo-division

## Agents
### dev-division
- planner
- coder
- tester
- pr-creator

### ops-division
- monitor
- incident
- perf

### business-division
- researcher
- analyst
- marketer

### leadership-division
- pm
- management

## CEO Notes
<CEOが判断した変更履歴・理由をここに記録>
```

---

## CEO レポートの出力形式

```
CEO Division 完了報告 [YYYY-MM-DD HH:MM]:
- モード: [日次 / 通常]
- チーム評価: [異常なし / 変更あり]
- 実行した変更:
  - 追加: <エージェント名>（理由）
  - 削除: <エージェント名>（理由）
- 次回確認: 15分後
```

---

## 実装範囲

### 変更・追加が必要なファイル

| ファイル | 変更内容 |
|---------|---------|
| `~/.claude/skills/agent-team/SKILL.md` | `_run ceo` の追加、`start` コマンドの Cron 登録変更 |
| `~/.claude/skills/agent-team/agents/ceo-division/SKILL.md` | 新規作成（CEO Division の動作定義） |
| `~/.claude/skills/agent-team/active-agents.md` | 新規作成（初期チーム構成） |
| `~/.claude/skills/agent-team/control.md` | `cron_ids.leadership` → `cron_ids.ceo` |

### 変更しないファイル

- 既存の各 Division・Agent の SKILL.md（CEO から呼ばれる構造は変えない）
- `leadership-log.md`（CEOが読む対象、書き込みは PM Agent が担当）

---

## 考慮事項・制約

- CEO は Leadership Division を1日1回しか完全実行しないため、GitHub Issue の過剰生成は発生しない
- エージェント自律生成の品質は CEO の判断に依存する。生成された SKILL.md が意図通りか確認したい場合は GitHub Issue で通知する仕組みを将来追加できる
- `/agent-team start` を再実行すると Cron が再登録される（既存の動作と同様）
