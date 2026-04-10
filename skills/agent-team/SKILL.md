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

注意：前のセッションの CronJob はセッション終了時に自動無効化されている。control.md を上書きすることで古い cron_ids もリセットされる。

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
   Read ツールで control.md を読んでから Edit ツールで各 cron_ids を更新する。

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

ファイルが存在しない場合は「Agent team は未起動です。」と出力して終了する。

1. `~/.claude/skills/agent-team/control.md` を Read ツールで読む。
2. control.md の `enabled` を `false` に更新する（Edit ツールを使用）。
3. cron_ids.dev, cron_ids.ops, cron_ids.business の各値を確認し、null でない場合のみ CronDelete を実行する。null の場合はスキップする。
4. control.md の `cron_ids` をすべて `null` に更新する（Edit ツールを使用）。
5. 以下を出力する：
   ```
   Agent team stopped. すべての CronJob を削除しました。
   ```

---

### /agent-team pause <duration>

control.md が存在しない場合は「Agent team は未起動です。先に /agent-team start を実行してください。」と出力して終了する。

1. `$ARGUMENTS` から duration を解析する。受け入れる単位: `m`（分）、`h`（時間）、`d`（日）。例: `pause 30m` → 30分後、`pause 24h` → 24時間後、`pause 2d` → 2日後。
2. 現在時刻 + duration の ISO8601 形式の日時を計算する：
   ```bash
   # Linux の場合
   date -d "+24 hours" -Iseconds 2>/dev/null || date -v+24H "+%Y-%m-%dT%H:%M:%S"
   ```
3. Read ツールで control.md を読み、Edit ツールで `pause_until` を計算した日時で更新する。
4. 以下を出力する：
   ```
   Agent team paused until <計算した日時>。
   CronJob は起動しますが、オーケストレーターが即座に終了します。
   /agent-team start で再開できます（pause_until がリセットされます）。
   ```

---

### /agent-team status

1. `~/.claude/skills/agent-team/control.md` を Read ツールで読む。
   ファイルが存在しない場合は「Agent team は未起動です。/agent-team start で開始してください。」と出力して終了。
2. enabled, pause_until, last_run の値を確認する。
3. 以下のフォーマットで出力する：

```
=== Agent Team Status ===
状態: [稼働中 / 停止中 / 一時停止中（<pause_until> まで）]
最終実行: [last_run の値 または "未実行"]
CronJob IDs:
  Dev: [cron_ids.dev の値]
  Ops: [cron_ids.ops の値]
  Business: [cron_ids.business の値]
```

状態の判定：
- `enabled: false` → 停止中
- `pause_until` が現在時刻より未来 → 一時停止中
- それ以外 → 稼働中

---

## オーケストレーターモード（Cron から `/agent-team _run <division>` で呼ばれる）

### 起動時チェック

control.md が存在しない場合は「control.md が見つかりません。/agent-team start を実行してください。」と出力して終了する。

1. `~/.claude/skills/agent-team/control.md` を Read ツールで読む。
2. `enabled: false` の場合 → 「Agent team is disabled. 終了します。」と出力して終了。
3. `pause_until` が設定されており現在時刻より未来の場合 → 「Paused until <日時>. 終了します。」と出力して終了。
4. Edit ツールで control.md の `last_run` を現在の ISO8601 日時で更新する：
   ```bash
   date -Iseconds 2>/dev/null || date "+%Y-%m-%dT%H:%M:%S"
   ```

### _run dev（Dev Division を実行）

起動時チェックを通過後、以下を実行する：

1. `~/.claude/skills/agent-team/agents/dev-division/SKILL.md` を Read ツールで読む。
2. そのプロンプト内容で Agent tool を起動する（subagent_type: general-purpose）。
3. Dev Division からの完了報告を出力する。

### _run ops（Ops Division を実行）

起動時チェックを通過後、以下を出力して終了：
```
[Ops Division] PLACEHOLDER - Plan 3 で実装予定
```

### _run business（Business Division を実行）

起動時チェックを通過後、以下を出力して終了：
```
[Business Division] PLACEHOLDER - Plan 4 で実装予定
```

---
