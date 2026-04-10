# 自律エージェントチーム - Plan 1: Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 制御レイヤー（control.md + start/stop/pause/status）と Chief Orchestrator の骨格を構築し、`/agent-team` コマンドで自律エージェントチームを制御できる状態にする。

**Architecture:** メインの SKILL.md が引数に応じて制御コマンドモード（start/stop/pause/status）と Cron 起動時のオーケストレーターモードを切り替える。状態は `~/.claude/skills/agent-team/control.md` に永続化。

**Tech Stack:** Claude Code (superpowers), SKILL.md files, CronCreate/CronDelete, Bash

> **CronJob の制約:** CronCreate はセッション内のみ有効。Claude セッション終了でジョブは消えるため、セッション開始時に `/agent-team start` を実行する運用とする。7日後に自動期限切れ（その時点で再度 start が必要）。

---

> **このプランは4部構成の Phase 1。**
> - Plan 1 (本ファイル): Foundation — 制御レイヤー + Chief Orchestrator 骨格
> - Plan 2: Dev Division — Planner / Coder / Tester / PR Creator
> - Plan 3: Ops Division — Monitor / Incident / Perf
> - Plan 4: Business Division — Researcher / Analyst / Marketer

---

## File Structure

| ファイル | 場所 | 役割 |
|---------|------|------|
| `skills/agent-team/SKILL.md` | リポジトリ（開発元） | Chief Orchestrator + 制御コマンド |
| `skills/agent-team/agents/.gitkeep` | リポジトリ | agents/ ディレクトリの保持 |
| `~/.claude/skills/agent-team/SKILL.md` | グローバル（インストール先） | 実行時に参照されるスキル |
| `~/.claude/skills/agent-team/control.md` | グローバル（ランタイム生成） | 状態管理ファイル（enabled/pause_until/last_run/cron_ids） |

---

### Task 1: ディレクトリ構造を作成する

**Files:**
- Create: `skills/agent-team/SKILL.md`
- Create: `skills/agent-team/agents/.gitkeep`

- [ ] **Step 1: ディレクトリを作成する**

```bash
mkdir -p skills/agent-team/agents
touch skills/agent-team/agents/.gitkeep
```

- [ ] **Step 2: 作成を確認する**

```bash
ls -la skills/agent-team/
```

Expected:
```
drwxr-xr-x  agents/
```

- [ ] **Step 3: 空の SKILL.md を作成する**

`skills/agent-team/SKILL.md` を以下の内容で作成する：

```markdown
---
name: agent-team
description: >
  自律エージェントチームの制御インターフェース。
  Use when the user invokes /agent-team with start, stop, pause, or status.
  Also invoked by CronJob as Chief Orchestrator.
argument-hint: "[start|stop|pause <duration>|status]"
---

# Agent Team (placeholder - see Task 3)
```

- [ ] **Step 4: Commit**

```bash
git add skills/agent-team/
git commit -m "feat: agent-team skill directory structure"
```

---

### Task 2: control.md のスキーマを定義する

**Files:**
- Modify: `skills/agent-team/SKILL.md`（スキーマのドキュメントとして）

control.md はランタイムに生成されるファイルで、リポジトリには含まない。スキーマをドキュメント化しておく。

- [ ] **Step 1: control.md のスキーマを理解する**

control.md は以下の YAML フォーマットで `~/.claude/skills/agent-team/control.md` に配置される：

```yaml
enabled: true
pause_until: null
last_run: null
cron_ids:
  dev: null
  ops: null
  business: null
```

各フィールド：
- `enabled`: `true` で稼働、`false` で停止
- `pause_until`: ISO8601 形式の日時。現在時刻より未来なら一時停止
- `last_run`: 最終実行日時（オーケストレーターが自動更新）
- `cron_ids`: CronCreate が返す job ID を保存（CronDelete で使用）

- [ ] **Step 2: スキーマを SKILL.md にコメントとして記載する**

`skills/agent-team/SKILL.md` の先頭に追記（Task 3 の内容で上書きするので今は省略可）

- [ ] **Step 3: Commit は Task 3 と合わせて行う**

---

### Task 3: 制御コマンドを実装する（start / stop / pause / status）

**Files:**
- Modify: `skills/agent-team/SKILL.md`

- [ ] **Step 1: SKILL.md を以下の内容で上書きする**

```markdown
---
name: agent-team
description: >
  自律エージェントチームの制御インターフェースおよび Chief Orchestrator。
  Use when the user invokes /agent-team with start, stop, pause, or status.
  Also invoked by CronJob as Chief Orchestrator (no args).
argument-hint: "[start|stop|pause <duration>|status]"
---

# Agent Team

$ARGUMENTS を確認して動作を切り替える。

---

## 制御コマンドモード（引数あり）

### /agent-team start

1. `~/.claude/skills/agent-team/` ディレクトリが存在しない場合は作成する：
   ```bash
   mkdir -p ~/.claude/skills/agent-team/agents
   ```

2. control.md を以下の内容で書き込む（`pause_until` も null にリセットされる）：
   ```bash
   cat > ~/.claude/skills/agent-team/control.md << 'EOF'
   enabled: true
   pause_until: null
   last_run: null
   cron_ids:
     dev: null
     ops: null
     business: null
   EOF
   ```

3. CronCreate で3つのジョブを作成する：
   - Dev Division: 毎時7分 (`7 * * * *`)
     - prompt: `/agent-team _run dev`
   - Ops Division: 15分ごと (`*/15 * * * *`)
     - prompt: `/agent-team _run ops`
   - Business Division: 毎週月曜9時7分 (`7 9 * * 1`)
     - prompt: `/agent-team _run business`

4. 各 CronCreate が返す job ID を control.md の `cron_ids` に書き込む。

5. 以下を出力する：
   ```
   Agent team started.
   - Dev Division: 毎時起動（Cron: 7 * * * *）
   - Ops Division: 15分ごと起動（Cron: */15 * * * *）
   - Business Division: 毎週月曜9:07起動（Cron: 7 9 * * 1）

   注意: CronJob はこの Claude セッション内でのみ有効です。
   セッション再開時に /agent-team start を再実行してください。
   7日後に自動期限切れになります。
   ```

---

### /agent-team stop

1. `~/.claude/skills/agent-team/control.md` を読む。
2. `enabled: false` に更新する：
   ```bash
   # control.md の enabled を false に書き換える
   ```
3. control.md の `cron_ids` に記録された各 job ID で CronDelete を実行する（null でないものすべて）。
4. control.md の `cron_ids` をすべて null に更新する。
5. 以下を出力する：
   ```
   Agent team stopped. すべての CronJob を削除しました。
   ```

---

### /agent-team pause <duration>

1. `$ARGUMENTS` から duration を解析する（例: `pause 24h` → 24時間後、`pause 2d` → 2日後）。
2. 現在時刻 + duration の ISO8601 形式の日時を計算する：
   ```bash
   # 例: 24h の場合
   date -d "+24 hours" -Iseconds
   # または macOS: date -v+24H "+%Y-%m-%dT%H:%M:%S"
   ```
3. control.md の `pause_until` を計算した日時で更新する。
4. 以下を出力する：
   ```
   Agent team paused until <計算した日時>。
   CronJob は起動しますが、オーケストレーターが即座に終了します。
   /agent-team start で再開できます（pause_until がリセットされます）。
   ```

---

### /agent-team status

1. `~/.claude/skills/agent-team/control.md` を読む。
   ファイルが存在しない場合は「Agent team は未起動です。/agent-team start で開始してください。」と出力して終了。
2. 以下のフォーマットで出力する：

```
=== Agent Team Status ===
状態: [稼働中 / 停止中 / 一時停止中（〜まで）]
最終実行: [last_run の値 または "未実行"]
CronJob IDs:
  Dev: [cron_ids.dev]
  Ops: [cron_ids.ops]
  Business: [cron_ids.business]
```

---

## オーケストレーターモード（Cron から `/agent-team _run <division>` で呼ばれる）

### 起動時チェック

1. `~/.claude/skills/agent-team/control.md` を読む。
2. `enabled: false` の場合 → 「Agent team is disabled. 終了します。」と出力して終了。
3. `pause_until` が現在時刻より未来の場合 → 「Paused until <日時>. 終了します。」と出力して終了。
4. `last_run` を現在の ISO8601 日時で更新する：
   ```bash
   # control.md の last_run を更新
   ```

### _run dev（Dev Division を実行）

Dev Division のエージェントは Plan 2 で実装する。
現時点では以下を出力して終了：
```
[Dev Division] PLACEHOLDER - Plan 2 で実装予定
```

### _run ops（Ops Division を実行）

Ops Division のエージェントは Plan 3 で実装する。
現時点では以下を出力して終了：
```
[Ops Division] PLACEHOLDER - Plan 3 で実装予定
```

### _run business（Business Division を実行）

Business Division のエージェントは Plan 4 で実装する。
現時点では以下を出力して終了：
```
[Business Division] PLACEHOLDER - Plan 4 で実装予定
```
```

- [ ] **Step 2: ファイルが正しく書き込まれたか確認する**

```bash
head -20 skills/agent-team/SKILL.md
```

Expected: frontmatter と `# Agent Team` が表示される

- [ ] **Step 3: Commit**

```bash
git add skills/agent-team/SKILL.md
git commit -m "feat: agent-team control commands (start/stop/pause/status) and orchestrator skeleton"
```

---

### Task 4: グローバルにインストールする

**Files:**
- `~/.claude/skills/agent-team/` (グローバルインストール先)

- [ ] **Step 1: インストールスクリプトを実行する**

```bash
mkdir -p ~/.claude/skills/agent-team/agents
cp -r skills/agent-team/. ~/.claude/skills/agent-team/
```

- [ ] **Step 2: インストール確認**

```bash
ls ~/.claude/skills/agent-team/
```

Expected:
```
SKILL.md  agents/
```

- [ ] **Step 3: Commit（インストール手順を README に追記）**

`README.md` の「Claude Code スキルとしての使い方」セクションに以下を追記する：

```markdown
## Agent Team スキルのインストール

```bash
mkdir -p ~/.claude/skills/agent-team/agents
cp -r skills/agent-team/. ~/.claude/skills/agent-team/
```

### 使い方

```bash
# セッション開始時に起動（セッション中のみ有効）
/agent-team start

# 停止
/agent-team stop

# 一時停止（例: 24時間）
/agent-team pause 24h

# 状態確認
/agent-team status
```
```

```bash
git add README.md
git commit -m "docs: agent-team インストール手順を README に追記"
```

---

### Task 5: 制御レイヤーを手動で検証する

**Files:** なし（検証のみ）

- [ ] **Step 1: /agent-team start を実行する**

Claude Code で以下を実行：
```
/agent-team start
```

Expected output（正確な job ID は異なる）:
```
Agent team started.
- Dev Division: 毎時起動（Cron: 7 * * * *）
- Ops Division: 15分ごと起動（Cron: */15 * * * *）
- Business Division: 毎週月曜9:07起動（Cron: 7 9 * * 1）

注意: CronJob はこの Claude セッション内でのみ有効です。
```

- [ ] **Step 2: control.md が作成されたか確認する**

```bash
cat ~/.claude/skills/agent-team/control.md
```

Expected:
```yaml
enabled: true
pause_until: null
last_run: null
cron_ids:
  dev: <job_id>
  ops: <job_id>
  business: <job_id>
```

- [ ] **Step 3: /agent-team status を実行する**

```
/agent-team status
```

Expected:
```
=== Agent Team Status ===
状態: 稼働中
最終実行: 未実行
CronJob IDs:
  Dev: <job_id>
  Ops: <job_id>
  Business: <job_id>
```

- [ ] **Step 4: /agent-team pause 1h を実行する**

```
/agent-team pause 1h
```

Expected:
```
Agent team paused until <1時間後の日時>。
```

- [ ] **Step 5: pause 状態で Cron が無視されることを確認する**

数分待って、`/agent-team _run ops` を手動で呼び出す：
```
/agent-team _run ops
```

Expected:
```
Paused until <日時>. 終了します。
```

- [ ] **Step 6: /agent-team start で resume する（pause_until をリセット）**

```
/agent-team start
```

control.md の `pause_until` が `null` に戻っていることを確認：
```bash
cat ~/.claude/skills/agent-team/control.md
```

- [ ] **Step 7: /agent-team stop を実行する**

```
/agent-team stop
```

Expected:
```
Agent team stopped. すべての CronJob を削除しました。
```

- [ ] **Step 8: 停止後に _run が無視されることを確認する**

```
/agent-team _run dev
```

Expected:
```
Agent team is disabled. 終了します。
```

---

### Task 6: Plan 2 への引き継ぎ準備

**Files:**
- Create: `skills/agent-team/agents/dev-division/SKILL.md`（プレースホルダー）

- [ ] **Step 1: Dev Division のプレースホルダーを作成する**

```bash
mkdir -p skills/agent-team/agents/dev-division
```

`skills/agent-team/agents/dev-division/SKILL.md`:

```markdown
---
name: agent-team-dev
description: >
  Dev Division orchestrator. Planner → Coder → Tester → PR Creator の順で実行する。
  Chief Orchestrator から Agent tool で呼ばれる。
---

# Dev Division (Plan 2 で実装予定)

このスキルは Plan 2 で実装される。
```

- [ ] **Step 2: Commit**

```bash
git add skills/agent-team/agents/
git commit -m "feat: dev-division placeholder for Plan 2"
```

- [ ] **Step 3: グローバルインストールを更新する**

```bash
cp -r skills/agent-team/. ~/.claude/skills/agent-team/
```

---

## 完了チェックリスト

Plan 1 完了の条件：

- [ ] `/agent-team start` で3つの CronJob が作成される
- [ ] `~/.claude/skills/agent-team/control.md` に状態が永続化される
- [ ] `/agent-team stop` で CronJob が削除される
- [ ] `/agent-team pause <duration>` で一時停止できる
- [ ] `/agent-team status` で現在の状態が表示される
- [ ] Cron から `_run dev/ops/business` が呼ばれた時、制御チェックが正しく動作する
- [ ] `~/.claude/skills/agent-team/` にグローバルインストール済み

---

## 次のステップ

Plan 1 完了後、Plan 2（Dev Division）に進む。
Plan 2 では以下を実装する：
- Planner Agent（Issue → 設計書）
- Coder Agent（設計書 → 実装 → ブランチ）
- Tester Agent（テスト実行・結果判定）
- PR Creator Agent（PR作成・説明文生成）
- Dev Division オーケストレーター（上記4エージェントを順次起動）
