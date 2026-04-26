#!/usr/bin/env bash
# chatwork-notify.sh — Chatwork API v2 へスタンドアップレポートを送信する
#
# 使用方法:
#   STANDUP_CHATWORK_TOKEN=<token> STANDUP_CHATWORK_ROOM_ID=<room_id> \
#     ./chatwork-notify.sh "レポートテキスト"
#
# 環境変数:
#   STANDUP_CHATWORK_TOKEN   — Chatwork API トークン（必須）
#   STANDUP_CHATWORK_ROOM_ID — 送信先ルーム ID（必須）

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
if [ -z "${STANDUP_CHATWORK_TOKEN:-}" ]; then
  echo "エラー: 環境変数 STANDUP_CHATWORK_TOKEN が設定されていません。" >&2
  echo "設定方法: export STANDUP_CHATWORK_TOKEN='your_api_token'" >&2
  exit 1
fi

if [ -z "${STANDUP_CHATWORK_ROOM_ID:-}" ]; then
  echo "エラー: 環境変数 STANDUP_CHATWORK_ROOM_ID が設定されていません。" >&2
  echo "設定方法: export STANDUP_CHATWORK_ROOM_ID='your_room_id'" >&2
  exit 1
fi

# --- 定数 ---
CHATWORK_API_BASE="https://api.chatwork.com/v2"
RETRY_COUNT="${STANDUP_CHATWORK_RETRY:-3}"
RETRY_INTERVAL="${STANDUP_CHATWORK_RETRY_INTERVAL:-2}"

# --- 送信関数 ---
send_to_chatwork() {
  local token="$1"
  local room_id="$2"
  local message="$3"

  local http_status
  http_status=$(curl -s -o /tmp/chatwork_response.json -w "%{http_code}" \
    -X POST \
    -H "X-ChatWorkToken: ${token}" \
    --data-urlencode "body=${message}" \
    "${CHATWORK_API_BASE}/rooms/${room_id}/messages")

  echo "$http_status"
}

# --- リトライループ ---
attempt=0
success=false

while [ "$attempt" -lt "$RETRY_COUNT" ]; do
  attempt=$((attempt + 1))

  http_status=$(send_to_chatwork \
    "$STANDUP_CHATWORK_TOKEN" \
    "$STANDUP_CHATWORK_ROOM_ID" \
    "$MESSAGE") || true

  if [ "$http_status" = "200" ]; then
    success=true
    break
  else
    echo "警告: Chatwork への送信に失敗しました（試行 ${attempt}/${RETRY_COUNT}、HTTP ${http_status}）。" >&2
    if [ -f /tmp/chatwork_response.json ]; then
      echo "レスポンス: $(cat /tmp/chatwork_response.json)" >&2
    fi

    if [ "$attempt" -lt "$RETRY_COUNT" ]; then
      echo "${RETRY_INTERVAL} 秒後にリトライします..." >&2
      sleep "$RETRY_INTERVAL"
    fi
  fi
done

# --- 結果 ---
if [ "$success" = true ]; then
  echo "Chatwork への通知を送信しました（ルーム ID: ${STANDUP_CHATWORK_ROOM_ID}）"
  exit 0
else
  echo "エラー: ${RETRY_COUNT} 回試行しましたが Chatwork への送信に失敗しました。" >&2
  echo "以下を確認してください:" >&2
  echo "  - STANDUP_CHATWORK_TOKEN が正しいか" >&2
  echo "  - STANDUP_CHATWORK_ROOM_ID が正しいか" >&2
  echo "  - ネットワーク接続が正常か" >&2
  exit 1
fi
