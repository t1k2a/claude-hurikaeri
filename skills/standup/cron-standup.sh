#!/usr/bin/env bash
# cron-standup.sh — 定期スタンドアップレポートの Webhook 送信スクリプト
#
# 使い方:
#   ./skills/standup/cron-standup.sh [morning|evening] [repo_path]
#
# 環境変数:
#   STANDUP_WEBHOOK_URL  — Slack/Discord の Webhook URL（必須）
#   STANDUP_RETRIES      — 最大リトライ回数（デフォルト: 3）
#   STANDUP_RETRY_WAIT   — リトライ間隔（秒、デフォルト: 5）
#
# cron 設定例（毎朝 9:00 に実行）:
#   0 9 * * 1-5 STANDUP_WEBHOOK_URL=https://hooks.slack.com/... /path/to/skills/standup/cron-standup.sh morning /path/to/repo >> /var/log/cron-standup.log 2>&1
#
# systemd timer 設定例（OnCalendar=Mon-Fri 09:00）:
#   [Unit]
#   Description=Daily standup Webhook sender
#   [Service]
#   Type=oneshot
#   Environment=STANDUP_WEBHOOK_URL=https://hooks.slack.com/...
#   ExecStart=/path/to/skills/standup/cron-standup.sh morning /path/to/repo
#   [Timer]
#   OnCalendar=Mon-Fri 09:00
#   Persistent=true

set -euo pipefail

# --- 引数 ---
MODE="${1:-morning}"
REPO_PATH="${2:-.}"
MAX_RETRIES="${STANDUP_RETRIES:-3}"
RETRY_WAIT="${STANDUP_RETRY_WAIT:-5}"

# --- Webhook URL チェック ---
if [ -z "${STANDUP_WEBHOOK_URL:-}" ]; then
  echo "[ERROR] STANDUP_WEBHOOK_URL が設定されていません。" >&2
  echo "  設定方法: export STANDUP_WEBHOOK_URL='https://hooks.slack.com/services/...'" >&2
  exit 1
fi

# --- リポジトリ存在チェック ---
if [ ! -d "$REPO_PATH" ]; then
  echo "[ERROR] リポジトリパスが存在しません: $REPO_PATH" >&2
  exit 1
fi

cd "$REPO_PATH"

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "[ERROR] $REPO_PATH は Git リポジトリではありません" >&2
  exit 1
fi

# --- Git 情報を収集 ---
SINCE_DATE=$(date -d "24 hours ago" -Iseconds 2>/dev/null || date -v-24H "+%Y-%m-%dT%H:%M:%S")
REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
BRANCH=$(git branch --show-current)
COMMITS=$(git log --since="$SINCE_DATE" --oneline --no-merges 2>/dev/null || echo "（コミットなし）")

REPORT="[スタンドアップレポート: $MODE]
リポジトリ: $REPO_NAME ($BRANCH)
日時: $(date '+%Y-%m-%d %H:%M')

== 直近24時間のコミット ==
${COMMITS:-（なし）}"

# --- Webhook に POST（リトライ付き） ---
PAYLOAD=$(python3 -c "
import json, sys
text = sys.stdin.read()
print(json.dumps({'text': text}))
" <<< "$REPORT")

attempt=1
while [ "$attempt" -le "$MAX_RETRIES" ]; do
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "$STANDUP_WEBHOOK_URL" 2>/dev/null || echo "000")

  if [ "$HTTP_STATUS" -ge 200 ] && [ "$HTTP_STATUS" -lt 300 ]; then
    echo "[OK] Webhook 送信成功 (attempt=$attempt, status=$HTTP_STATUS)"
    exit 0
  fi

  echo "[WARN] 送信失敗 (attempt=$attempt/$MAX_RETRIES, status=$HTTP_STATUS)" >&2

  if [ "$attempt" -lt "$MAX_RETRIES" ]; then
    sleep "$RETRY_WAIT"
  fi

  attempt=$((attempt + 1))
done

echo "[ERROR] Webhook 送信が ${MAX_RETRIES} 回失敗しました。Webhook URL を確認してください。" >&2
exit 1
