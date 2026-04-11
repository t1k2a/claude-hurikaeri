# 自律エージェントチーム設計書

**日付:** 2026-04-10
**ステータス:** 承認済み

---

## 概要

superpowers のみを使用して、開発・運用・ビジネスの3部門にわたる自律的なエージェントチームをグローバルに構築する。Chief Orchestrator がハブとなり、各部門の専門エージェントをスポーンして全体を統括する。

---

## アーキテクチャ

### ハブ＆スポーク型

```
CronJob（定期トリガー）
  └─ Chief Orchestrator Agent
       │
       ├─ Leadership Division（日次）
       │    ├─ PM Agent           ← 全Division状況集約・QA・バグ/リファクタ提案・Issue化
       │    └─ 経営 Agent          ← マネタイズ確認・PMレポートから機能追加/修正要望を決定
       │
       ├─ Dev Division（1時間ごと）
       │    ├─ Planner Agent      ← Issue解析・設計書生成
       │    ├─ Coder Agent        ← 実装・ブランチ作成
       │    ├─ Tester Agent       ← テスト実行・品質検証
       │    └─ PR Creator Agent   ← PR作成・説明文生成
       │
       ├─ Ops Division
       │    ├─ Monitor Agent      ← エラー・メトリクス監視（15分ごと）
       │    ├─ Incident Agent     ← 障害調査・修正指示
       │    └─ Perf Agent         ← ボトルネック分析・最適化提案
       │
       └─ Business Division
            ├─ Researcher Agent   ← 競合調査・拡散チャネル調査（週次）
            ├─ Analyst Agent      ← GitHub統計・成長指標分析（週次）
            └─ Marketer Agent     ← 告知文・SNS投稿・ブログ下書き生成（週次）
```

### ファイル構成（グローバルインストール）

```
~/.claude/skills/agent-team/
  ├─ SKILL.md            ← Chief Orchestrator エントリポイント
  ├─ control.md          ← 状態管理ファイル（enabled/disabled/pause_until）
  └─ agents/
       ├─ leadership-division/SKILL.md
       ├─ pm/SKILL.md
       ├─ management/SKILL.md
       ├─ planner/SKILL.md
       ├─ coder/SKILL.md
       ├─ tester/SKILL.md
       ├─ pr-creator/SKILL.md
       ├─ monitor/SKILL.md
       ├─ incident/SKILL.md
       ├─ perf/SKILL.md
       ├─ researcher/SKILL.md
       ├─ analyst/SKILL.md
       └─ marketer/SKILL.md
```

---

## データフロー

### Leadership Flow（日次）

```
CronJob（日次）
  → PM Agent
    ├─ 1. チーム状況を集約（git log, open Issues/PRs, Ops ログ）
    ├─ 2. 動作確認・QA → バグ/リファクタ候補を発見 → GitHub Issue 化（"agent-task" ラベル）
    ├─ 3. 経営 Agent にデイリーレポートを渡す
    └─ 4. 経営 Agent からの要望を受け取り → GitHub Issue 化（"agent-task" ラベル）

  経営 Agent（PM Agent から呼ばれる）
    ├─ PMレポートを確認
    ├─ マネタイズ観点でサービスを評価
    └─ 機能追加・修正の優先度付き要望リストを PM Agent に返す

Dev Division が次サイクルで "agent-task" ラベルの Issue を自動処理
```

**中継ファイル（状態共有）:**
- `~/.claude/skills/agent-team/leadership-log.md` — PM/経営のデイリーレポート履歴（最新5件保持）

### Dev Flow（Issue検知時）

```
GitHub Issue/PR
  → Planner Agent（設計書生成）
  → Coder Agent（実装、ブランチ作成）
  → Tester Agent（テスト実行・結果判定）
  → PR Creator Agent（PR作成、説明文・チェックリスト付与）
  → 人間が最終PRレビュー（唯一の承認ステップ）
```

### Ops Flow（15分ごと）

```
CronJob
  → Monitor Agent（ログ・メトリクス確認）
    ├─ 異常なし → レポートのみ記録
    └─ 異常あり → Incident Agent起動（Agent tool経由）
                    → 原因調査
                    → Agent tool で Coder Agent に修正依頼
                       OR Agent tool で Perf Agent に最適化依頼
```

### Business Flow（週次）

```
CronJob
  → Researcher Agent（競合・チャネル調査）
  → Analyst Agent（成長指標・統計分析）
  → Marketer Agent（調査結果を元にコンテンツ生成）
```

---

## 制御レイヤー

### control.md の構造

```yaml
enabled: true          # false にすると全エージェント停止
pause_until: null      # ISO8601形式の日時を入れると一時停止
last_run: null         # 最終実行日時（自動更新）
```

### 操作スキル

| コマンド | 動作 |
|---------|------|
| `/agent-team start` | CronCreate + control.md を enabled:true に |
| `/agent-team stop` | CronDelete + control.md を enabled:false に |
| `/agent-team pause 24h` | pause_until を現在時刻+24時間に設定 |
| `/agent-team status` | 現在の状態・直近ログを表示 |

Chief Orchestrator は起動時に必ず control.md を確認し、`enabled: false` または有効な `pause_until` があれば即座に終了する。

---

## エラーハンドリング

### 各エージェントの失敗時

```
エージェント失敗
  → Chief Orchestrator が TaskUpdate で失敗を記録
  → リトライ（最大3回）
    ├─ 成功 → 続行
    └─ 3回失敗
         ├─ Dev Agent → PRに "needs-human" ラベルを付けてスキップ
         └─ Ops Agent → ログに記録してサイレント継続
```

### 方針

- Ops系の失敗はサービスを止めない（サイレント継続）
- Dev系の詰まりは人間にエスカレーション（"needs-human" ラベル）
- Chief Orchestrator 自身の失敗は次のCronサイクルで自動リカバリ

---

## テスト戦略

### Unit テスト

各エージェントスキルを単体で呼び出し、期待する成果物（設計書・コード・PR・レポート）が生成されるかを確認する。

### Integration テスト

1. **Dev Flow:** ダミーIssueを投入し、Planner → Coder → Tester → PR Creator まで完走するか確認
2. **Ops Flow:** 意図的なエラーログを仕込み、Monitor → Incident の連鎖が発火するか確認

### 制御レイヤーテスト

- `/agent-team stop` 後にCronが起動しないことを確認
- `/agent-team pause 1h` 後、1時間経過後に自動再開することを確認

---

## スコープ外（将来検討）

- ユーザーフィードバック処理エージェント（ユーザー増加後に追加）
- GitHub Actions との連携
- Slack/外部サービス通知
- チームメンバー横断での共有設定

---

## 実装順序（推奨）

1. 制御レイヤー（control.md + start/stop/status スキル）← **完了**
2. Chief Orchestrator の骨格 ← **完了**
3. Dev Division（Planner → Coder → Tester → PR Creator）← **完了**
4. Ops Division（Monitor → Incident → Perf）
5. Business Division（Researcher → Analyst → Marketer）
6. Leadership Division（PM → 経営）← **追加**
7. Integration テスト
