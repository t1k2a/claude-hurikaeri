# Leadership Division デモシナリオ

## 概要

Leadership Division は PM Agent → 経営 Agent → PM Agent (post_report) の順で自律的に動作し、プロジェクトの健全性チェックと経営判断を自動化します。

毎日の実行により、以下を自動化します：

- チーム状況の集約（Git コミット・Issue・PR）
- QA・バグ・リファクタリング候補の発見と Issue 化
- 経営観点（マネタイズ・ユーザー価値・リスク）でのサービス評価
- 経営要望の GitHub Issue 化
- `leadership-log.md` への実行履歴の保存

## アーキテクチャ

```
Chief Orchestrator
       |
       v
Leadership Division Orchestrator (agent-team-leadership)
       |
       |-- Step 1: PM Agent (report モード)
       |     └── Git/Issue/PR 状況を収集 → QA Issue 化 → デイリーレポート生成
       |
       |-- Step 2: 経営 Agent
       |     └── PM レポートを受け取り → マネタイズ観点で評価 → 要望リスト生成
       |
       `-- Step 3: PM Agent (post_report モード)
             └── 経営要望を GitHub Issue 化 → leadership-log.md 更新
```

各エージェントは `~/.claude/skills/agent-team/agents/` 配下の SKILL.md で定義されており、Leadership Division Orchestrator が順番に Agent tool で呼び出します。

## 実行方法

### 手動実行

```bash
# Claude Code から実行
/agent-team _run leadership
```

### 自動実行（CronJob）

Leadership Division は毎日 8:57 に自動起動します（`/agent-team start` 後）。

```bash
# CronJob を有効にする
/agent-team start

# CronJob を停止する
/agent-team stop

# 現在のステータス確認
/agent-team status
```

## 実行フロー

### Step 1: PM Agent（report モード）

1. 直近 24 時間の Git コミット・オープン Issue・PR を収集する
2. 変更ファイルを分析して QA・バグ候補・リファクタ提案を発見する
3. 発見があれば `agent-task,qa` ラベルで GitHub Issue を作成する
4. デイリーレポートを生成して Leadership Division Orchestrator に返す

**出力形式:**
```
## 🗂️ PM デイリーレポート [YYYY-MM-DD]

### チーム状況
- 直近24時間のコミット数: N 件
- オープン Issue: N 件
- オープン PR: N 件（うちドラフト: N 件）
- 直近マージ PR: N 件

### QA・発見事項
<発見があれば記載、なければ「異常なし」>
Issue 化した項目: N 件

### 注目点
<経営 Agent が判断すべき重要事項>

### サービス状態サマリー
<Good / Warning / Critical とその理由>
```

### Step 2: 経営 Agent

1. PM レポートを受け取りサービス状態・開発速度・QA 発見を確認する
2. マネタイズ観点（ユーザー価値・成長収益・リスク）でサービスを評価する
3. 優先度付き要望リストを生成して Leadership Division Orchestrator に返す

**出力形式:**
```
## 👔 経営レスポンス [YYYY-MM-DD]

### サービス評価
<マネタイズ観点での総評>

### 要望リスト（優先度順）

#### 優先度: 高
1. <要望タイトル>
   - 背景: <なぜ必要か>
   - 期待効果: <マネタイズ/ユーザー価値への影響>

#### 優先度: 中
...

### 経営からのメッセージ
<チームへの一言>
```

### Step 3: PM Agent（post_report モード）

1. 経営 Agent の要望リストを受け取る
2. 要望を優先度順に `agent-task,management-request` ラベルで GitHub Issue を作成する
3. `~/.claude/skills/agent-team/leadership-log.md` を更新する（最新 5 件を保持）
4. 完了を報告する

### Step 4: Leadership Division Orchestrator が完了を報告

```
🏛️ Leadership Division 完了報告:
- PM レポート: 生成済み
- 経営レスポンス: 生成済み
- Issue 化: PM Agent が実施
- leadership-log.md: 更新済み
```

## 出力例

以下は代表的な実行結果のサンプルです（初回実行後は `~/.claude/skills/agent-team/leadership-log.md` に実際の出力が記録されます）。

### PM デイリーレポートのサンプル

```markdown
## 🗂️ PM デイリーレポート 2026-04-11

### チーム状況
- 直近24時間のコミット数: 3 件
- オープン Issue: 5 件
- オープン PR: 1 件（うちドラフト: 0 件）
- 直近マージ PR: 2 件

### QA・発見事項
- バグ候補: src/index.ts:42 — null チェックが不足している可能性
Issue 化した項目: 1 件

### 注目点
- #8 PR がレビュー待ちで 48 時間経過しています
- Issue #3 が 1 週間以上更新されていません

### サービス状態サマリー
Warning — PR レビューの遅延あり、null チェック漏れの疑いあり
```

### 経営レスポンスのサンプル

```markdown
## 👔 経営レスポンス 2026-04-11

### サービス評価
開発速度は安定しているが、PR レビューの遅延がリリースサイクルに影響しています。
QA で発見された null チェック漏れはユーザー影響が懸念されるため早急な対応を推奨します。

### 要望リスト（優先度順）

#### 優先度: 高
1. null チェック漏れの修正
   - 背景: 本番環境でのクラッシュリスクあり
   - 期待効果: サービス安定性向上、ユーザー離脱防止

#### 優先度: 中
1. PR レビュープロセスの改善
   - 背景: レビュー待ちが開発速度のボトルネックになっている
   - 期待効果: リリースサイクルの短縮

### 経営からのメッセージ
安定したペースで開発が続いています。品質維持を最優先に引き続きよろしくお願いします。
```

## 期待される成果物

実行ごとに以下が生成されます：

- **GitHub Issues（QA 発見）**: `agent-task,qa` ラベル付き、バグ候補・リファクタ提案
- **GitHub Issues（経営要望）**: `agent-task,management-request` ラベル付き、優先度付き要望
- **leadership-log.md の更新**: `~/.claude/skills/agent-team/leadership-log.md` に最新 5 件のレポートを保持
- **PM デイリーレポート**: チーム状況・QA 発見・サービス健全性の評価

## トラブルシューティング

### PM Agent が失敗する場合

**症状**: `PM Agent が失敗しました。Leadership Division を終了します。` と出力される

**原因と対処**:
- `gh` CLI が認証されていない → `gh auth login` で認証する
- Git リポジトリのルートで実行されていない → 正しいディレクトリで実行する
- PM レポートの出力に `## 🗂️ PM デイリーレポート` が含まれていない → PM Agent の SKILL.md を確認する

### 経営 Agent が失敗する場合

**症状**: `経営 Agent が失敗しました。PM レポートのみで終了します。` と出力される

**原因と対処**:
- PM レポートが空または不正な形式 → PM Agent の出力を確認する
- 経営 Agent の SKILL.md が存在しない → `~/.claude/skills/agent-team/agents/management/SKILL.md` を確認する

### GitHub Issue が作成されない場合

**症状**: Issue 化のステップがスキップされる

**原因と対処**:
- `gh` CLI がインストールされていない → `brew install gh` (macOS) または公式ドキュメントに従いインストールする
- リポジトリへの書き込み権限がない → `gh auth status` で権限を確認する

### CronJob が起動しない場合

**症状**: `leadership_division` が 8:57 に実行されない

**原因と対処**:
- `/agent-team start` が実行されていない → `/agent-team start` で CronJob を有効化する
- `/agent-team status` で CronJob の状態を確認する
- Claude Code のプロセスが起動していない → Claude Code を起動してから `/agent-team start` を実行する

### leadership-log.md が更新されない場合

**症状**: `~/.claude/skills/agent-team/leadership-log.md` が作成・更新されない

**原因と対処**:
- `post_report` モードの PM Agent が失敗している → Step 3 のログを確認する
- ファイルの書き込み権限がない → `~/.claude/skills/agent-team/` ディレクトリの権限を確認する
