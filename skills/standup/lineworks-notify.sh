#!/usr/bin/env bash
# lineworks-notify.sh — LINE WORKS Bot API v2 へスタンドアップレポートを送信する
#
# 使用方法:
#   STANDUP_LINE_WORKS_CLIENT_ID=<client_id> \
#   STANDUP_LINE_WORKS_CLIENT_SECRET=<client_secret> \
#   STANDUP_LINE_WORKS_BOT_NO=<bot_no> \
#   STANDUP_LINE_WORKS_CHANNEL_ID=<channel_id> \
#     ./lineworks-notify.sh "レポートテキスト"
#
# 環境変数:
#   STANDUP_LINE_WORKS_CLIENT_ID     — LINE WORKS Developer Console の Client ID（必須）
#   STANDUP_LINE_WORKS_CLIENT_SECRET — LINE WORKS Developer Console の Client Secret（必須）
#   STANDUP_LINE_WORKS_BOT_NO        — Bot 番号（必須）
#   STANDUP_LINE_WORKS_CHANNEL_ID    — 送信先チャンネル ID（必須）

set -euo pipefail

# --- 引数 ---
MESSAGE="${1:-}"
if [ -z "$MESSAGE" ]; then
  # 環境変数からも取得を試みる
  MESSAGE="${STANDUP_REPORT:-}"
fi

if [ -z "$MESSAGE" ]; then
  echo "エラー: 送信するメッセージが指定されていません。" >&2
  echo "使用方法: $0 \"レポートテキスト\"" >&2
  exit 1
fi

# --- 環境変数チェック ---
if [ -z "${STANDUP_LINE_WORKS_CLIENT_ID:-}" ]; then
  echo "エラー: 環境変数 STANDUP_LINE_WORKS_CLIENT_ID が設定されていません。" >&2
  echo "設定方法: export STANDUP_LINE_WORKS_CLIENT_ID='your_client_id'" >&2
  exit 1
fi

if [ -z "${STANDUP_LINE_WORKS_CLIENT_SECRET:-}" ]; then
  echo "エラー: 環境変数 STANDUP_LINE_WORKS_CLIENT_SECRET が設定されていません。" >&2
  echo "設定方法: export STANDUP_LINE_WORKS_CLIENT_SECRET='your_client_secret'" >&2
  exit 1
fi

if [ -z "${STANDUP_LINE_WORKS_BOT_NO:-}" ]; then
  echo "エラー: 環境変数 STANDUP_LINE_WORKS_BOT_NO が設定されていません。" >&2
  echo "設定方法: export STANDUP_LINE_WORKS_BOT_NO='your_bot_no'" >&2
  exit 1
fi

if [ -z "${STANDUP_LINE_WORKS_CHANNEL_ID:-}" ]; then
  echo "エラー: 環境変数 STANDUP_LINE_WORKS_CHANNEL_ID が設定されていません。" >&2
  echo "設定方法: export STANDUP_LINE_WORKS_CHANNEL_ID='your_channel_id'" >&2
  exit 1
fi

# --- 定数 ---
LINE_WORKS_AUTH_URL="https://auth.worksmobile.com/oauth2/v2.0/token"
LINE_WORKS_API_BASE="https://www.worksapis.com/v1.0"
RETRY_COUNT="${STANDUP_LINE_WORKS_RETRY:-3}"
RETRY_INTERVAL="${STANDUP_LINE_WORKS_RETRY_INTERVAL:-2}"

# --- アクセストークン取得関数 ---
get_access_token() {
  local client_id="$1"
  local client_secret="$2"

  local response
  response=$(curl -s -X POST "${LINE_WORKS_AUTH_URL}" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "grant_type=client_credentials" \
    --data-urlencode "client_id=${client_id}" \
    --data-urlencode "client_secret=${client_secret}" \
    --data-urlencode "scope=bot") || {
    echo ""
    return 1
  }

  # access_token フィールドを抽出する（python3 は依存を避けるため grep/sed で処理）
  echo "$response" | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"//;s/"//'
}

# --- メッセージ送信関数 ---
send_to_lineworks() {
  local access_token="$1"
  local bot_no="$2"
  local channel_id="$3"
  local message="$4"

  local payload
  payload=$(printf '{"content":{"type":"text","text":"%s"}}' \
    "$(printf '%s' "$message" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/g' | tr -d '\n' | sed 's/\\n$//')")

  local http_status
  http_status=$(curl -s -o /tmp/lineworks_response.json -w "%{http_code}" \
    -X POST \
    -H "Authorization: Bearer ${access_token}" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "${LINE_WORKS_API_BASE}/bots/${bot_no}/channels/${channel_id}/messages")

  echo "$http_status"
}

# --- メイン処理: アクセストークン取得 ---
ACCESS_TOKEN=""
token_attempt=0
while [ "$token_attempt" -lt "$RETRY_COUNT" ]; do
  token_attempt=$((token_attempt + 1))
  ACCESS_TOKEN=$(get_access_token \
    "$STANDUP_LINE_WORKS_CLIENT_ID" \
    "$STANDUP_LINE_WORKS_CLIENT_SECRET") || true

  if [ -n "$ACCESS_TOKEN" ]; then
    break
  fi

  echo "警告: アクセストークンの取得に失敗しました（試行 ${token_attempt}/${RETRY_COUNT}）。" >&2
  if [ "$token_attempt" -lt "$RETRY_COUNT" ]; then
    echo "${RETRY_INTERVAL} 秒後にリトライします..." >&2
    sleep "$RETRY_INTERVAL"
  fi
done

if [ -z "$ACCESS_TOKEN" ]; then
  echo "エラー: アクセストークンの取得に失敗しました。" >&2
  echo "以下を確認してください:" >&2
  echo "  - STANDUP_LINE_WORKS_CLIENT_ID が正しいか" >&2
  echo "  - STANDUP_LINE_WORKS_CLIENT_SECRET が正しいか" >&2
  echo "  - ネットワーク接続が正常か" >&2
  exit 1
fi

# --- メイン処理: メッセージ送信リトライループ ---
attempt=0
success=false

while [ "$attempt" -lt "$RETRY_COUNT" ]; do
  attempt=$((attempt + 1))

  http_status=$(send_to_lineworks \
    "$ACCESS_TOKEN" \
    "$STANDUP_LINE_WORKS_BOT_NO" \
    "$STANDUP_LINE_WORKS_CHANNEL_ID" \
    "$MESSAGE") || true

  if [ "$http_status" = "200" ] || [ "$http_status" = "201" ]; then
    success=true
    break
  else
    echo "警告: LINE WORKS への送信に失敗しました（試行 ${attempt}/${RETRY_COUNT}、HTTP ${http_status}）。" >&2
    if [ -f /tmp/lineworks_response.json ]; then
      echo "レスポンス: $(cat /tmp/lineworks_response.json)" >&2
    fi

    if [ "$attempt" -lt "$RETRY_COUNT" ]; then
      echo "${RETRY_INTERVAL} 秒後にリトライします..." >&2
      sleep "$RETRY_INTERVAL"
    fi
  fi
done

# --- 結果 ---
if [ "$success" = true ]; then
  echo "LINE WORKS への通知を送信しました（チャンネル ID: ${STANDUP_LINE_WORKS_CHANNEL_ID}）"
  exit 0
else
  echo "エラー: ${RETRY_COUNT} 回試行しましたが LINE WORKS への送信に失敗しました。" >&2
  echo "以下を確認してください:" >&2
  echo "  - STANDUP_LINE_WORKS_CLIENT_ID が正しいか" >&2
  echo "  - STANDUP_LINE_WORKS_CLIENT_SECRET が正しいか" >&2
  echo "  - STANDUP_LINE_WORKS_BOT_NO が正しいか" >&2
  echo "  - STANDUP_LINE_WORKS_CHANNEL_ID が正しいか" >&2
  echo "  - ネットワーク接続が正常か" >&2
  exit 1
fi
