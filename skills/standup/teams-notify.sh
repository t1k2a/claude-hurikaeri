#!/usr/bin/env bash
# teams-notify.sh — Microsoft Teams Webhook へスタンドアップレポートを送信する
#
# 使用方法:
#   STANDUP_TEAMS_WEBHOOK_URL=<webhook_url> ./teams-notify.sh "レポートテキスト"
#
# 環境変数:
#   STANDUP_TEAMS_WEBHOOK_URL — Microsoft Workflows (Power Automate) Webhook URL（必須）
#   STANDUP_TEAMS_PAYLOAD_TYPE — ペイロード形式: "adaptive_card" または "text"（デフォルト: "text"）
#   STANDUP_TEAMS_RETRY        — リトライ回数（デフォルト: 3）
#   STANDUP_TEAMS_RETRY_INTERVAL — リトライ間隔（秒、デフォルト: 2）
#
# Microsoft Workflows Webhook URL の取得方法:
#   Teams チャンネル → Workflows → 「Post to a channel when a webhook request is received」
#   → フローを作成 → 生成された URL を STANDUP_TEAMS_WEBHOOK_URL に設定する

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
if [ -z "${STANDUP_TEAMS_WEBHOOK_URL:-}" ]; then
  echo "エラー: 環境変数 STANDUP_TEAMS_WEBHOOK_URL が設定されていません。" >&2
  echo "設定方法: export STANDUP_TEAMS_WEBHOOK_URL='https://prod-xx.westus.logic.azure.com/...'" >&2
  echo "Webhook URL の取得: Teams チャンネル → Workflows → 「Post to a channel when a webhook request is received」" >&2
  exit 1
fi

# --- 定数 ---
PAYLOAD_TYPE="${STANDUP_TEAMS_PAYLOAD_TYPE:-text}"
RETRY_COUNT="${STANDUP_TEAMS_RETRY:-3}"
RETRY_INTERVAL="${STANDUP_TEAMS_RETRY_INTERVAL:-2}"

# --- ペイロード生成関数 ---
build_payload() {
  local message="$1"
  local payload_type="$2"

  if [ "$payload_type" = "adaptive_card" ]; then
    # Adaptive Card v1.4 形式
    python3 -c "
import json, sys
message = sys.argv[1]
payload = {
    'type': 'message',
    'attachments': [
        {
            'contentType': 'application/vnd.microsoft.card.adaptive',
            'content': {
                '\$schema': 'http://adaptivecards.io/schemas/adaptive-card.json',
                'type': 'AdaptiveCard',
                'version': '1.4',
                'body': [
                    {
                        'type': 'TextBlock',
                        'text': message,
                        'wrap': True
                    }
                ]
            }
        }
    ]
}
print(json.dumps(payload))
" "$message" 2>/dev/null
  else
    # シンプルテキスト形式（フォールバック）
    python3 -c "
import json, sys
message = sys.argv[1]
print(json.dumps({'text': message}))
" "$message" 2>/dev/null
  fi
}

# --- 送信関数 ---
send_to_teams() {
  local webhook_url="$1"
  local payload="$2"

  local http_status
  http_status=$(curl -s -o /tmp/teams_response.json -w "%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "$webhook_url")

  echo "$http_status"
}

# --- ペイロード生成 ---
PAYLOAD="$(build_payload "$MESSAGE" "$PAYLOAD_TYPE")"
if [ -z "$PAYLOAD" ]; then
  echo "エラー: ペイロードの生成に失敗しました。python3 が利用可能か確認してください。" >&2
  exit 1
fi

# --- リトライループ ---
attempt=0
success=false

while [ "$attempt" -lt "$RETRY_COUNT" ]; do
  attempt=$((attempt + 1))

  http_status=$(send_to_teams "$STANDUP_TEAMS_WEBHOOK_URL" "$PAYLOAD") || true

  if [ "$http_status" = "200" ] || [ "$http_status" = "202" ]; then
    success=true
    break
  else
    echo "警告: Teams への送信に失敗しました（試行 ${attempt}/${RETRY_COUNT}、HTTP ${http_status}）。" >&2
    if [ -f /tmp/teams_response.json ]; then
      echo "レスポンス: $(cat /tmp/teams_response.json)" >&2
    fi

    if [ "$attempt" -lt "$RETRY_COUNT" ]; then
      echo "${RETRY_INTERVAL} 秒後にリトライします..." >&2
      sleep "$RETRY_INTERVAL"
    fi
  fi
done

# --- 結果 ---
if [ "$success" = true ]; then
  echo "Microsoft Teams への通知を送信しました"
  exit 0
else
  echo "エラー: ${RETRY_COUNT} 回試行しましたが Teams への送信に失敗しました。" >&2
  echo "以下を確認してください:" >&2
  echo "  - STANDUP_TEAMS_WEBHOOK_URL が正しいか（Microsoft Workflows の URL を使用）" >&2
  echo "  - ネットワーク接続が正常か" >&2
  echo "  - Incoming Webhook（廃止予定）ではなく Workflows を使用しているか" >&2
  exit 1
fi
