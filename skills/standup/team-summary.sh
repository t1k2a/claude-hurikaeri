#!/usr/bin/env bash
# team-summary.sh — チームスタンドアップ集計・Webhook送信スクリプト
# Issue #43: 非同期スタンドアップ集計機能（チーム複数人対応）
#
# 使い方:
#   bash team-summary.sh [--webhook <URL>] [--history-dir <DIR>] [--date <YYYY-MM-DD>]
#
# 環境変数:
#   STANDUP_WEBHOOK_URL  — Webhook URL（--webhook より優先度低）
#   STANDUP_HISTORY_DIR  — 履歴ディレクトリ（デフォルト: ~/.standup-history）

set -euo pipefail

# ── デフォルト値 ──────────────────────────────────────────────
HISTORY_DIR="${STANDUP_HISTORY_DIR:-$HOME/.standup-history}"
WEBHOOK_URL="${STANDUP_WEBHOOK_URL:-}"
TARGET_DATE="$(date '+%Y-%m-%d')"

# ── 引数パース ────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --webhook)   WEBHOOK_URL="$2";    shift 2 ;;
    --history-dir) HISTORY_DIR="$2"; shift 2 ;;
    --date)      TARGET_DATE="$2";   shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# ── 履歴ディレクトリ確認 ──────────────────────────────────────
if [[ ! -d "$HISTORY_DIR" ]]; then
  echo "ERROR: 履歴ディレクトリが見つかりません: $HISTORY_DIR" >&2
  exit 1
fi

# ── メンバー一覧を取得（履歴ディレクトリのサブディレクトリ = メンバー名）─
mapfile -t MEMBERS < <(find "$HISTORY_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)

if [[ ${#MEMBERS[@]} -eq 0 ]]; then
  # サブディレクトリなし → フラットな JSON ファイルをシングルユーザーとして扱う
  mapfile -t MEMBERS < <(find "$HISTORY_DIR" -maxdepth 1 -name "*.json" -exec basename {} .json \; | sort)
  FLAT_MODE=true
else
  FLAT_MODE=false
fi

if [[ ${#MEMBERS[@]} -eq 0 ]]; then
  echo "ERROR: 集計対象のメンバーが見つかりません。" >&2
  exit 1
fi

# ── 集計変数 ──────────────────────────────────────────────────
RESPONDED_MEMBERS=()
NO_RESPONSE_MEMBERS=()
TODAY_ITEMS=""
BLOCKER_ITEMS=""
TOTAL=0
RESPONDED=0

# ── 各メンバーの回答を集計 ────────────────────────────────────
for MEMBER in "${MEMBERS[@]}"; do
  TOTAL=$((TOTAL + 1))

  # JSON ファイルのパスを決定
  if [[ "$FLAT_MODE" == "true" ]]; then
    JSON_FILE="$HISTORY_DIR/${MEMBER}.json"
  else
    JSON_FILE="$HISTORY_DIR/${MEMBER}/${TARGET_DATE}.json"
  fi

  if [[ ! -f "$JSON_FILE" ]]; then
    NO_RESPONSE_MEMBERS+=("$MEMBER")
    continue
  fi

  RESPONDED=$((RESPONDED + 1))
  RESPONDED_MEMBERS+=("$MEMBER")

  # JSON から項目を抽出（jq がなければ grep フォールバック）
  if command -v jq &>/dev/null; then
    TODAY="$(jq -r '.today // .today_plan // "" | if type == "array" then join(", ") else . end' "$JSON_FILE" 2>/dev/null || true)"
    BLOCKERS="$(jq -r '.blockers // .problems // "" | if type == "array" then join(", ") else . end' "$JSON_FILE" 2>/dev/null || true)"
    YESTERDAY="$(jq -r '.yesterday // .done // "" | if type == "array" then join(", ") else . end' "$JSON_FILE" 2>/dev/null || true)"
  else
    # grep フォールバック（シンプルなフラット JSON のみ対応）
    TODAY="$(grep -oP '"today"\s*:\s*"\K[^"]+' "$JSON_FILE" 2>/dev/null | head -1 || true)"
    BLOCKERS="$(grep -oP '"blockers"\s*:\s*"\K[^"]+' "$JSON_FILE" 2>/dev/null | head -1 || true)"
    YESTERDAY="$(grep -oP '"yesterday"\s*:\s*"\K[^"]+' "$JSON_FILE" 2>/dev/null | head -1 || true)"
  fi

  # 今日やること集約
  if [[ -n "$TODAY" ]]; then
    TODAY_ITEMS+="  - [${MEMBER}] ${TODAY}\n"
  fi

  # ブロッカー集約（空・"なし"・"none"・"-" は除外）
  if [[ -n "$BLOCKERS" && "$BLOCKERS" != "なし" && "$BLOCKERS" != "none" && "$BLOCKERS" != "-" ]]; then
    BLOCKER_ITEMS+="  - [${MEMBER}] ${BLOCKERS}\n"
  fi
done

# ── 参加率計算 ────────────────────────────────────────────────
if [[ $TOTAL -gt 0 ]]; then
  PARTICIPATION_RATE=$(( (RESPONDED * 100) / TOTAL ))
else
  PARTICIPATION_RATE=0
fi

# ── サマリーテキスト生成 ──────────────────────────────────────
SUMMARY_DATE="$(date '+%Y-%m-%d %H:%M')"
SUMMARY_TEXT="=== チームスタンドアップ集計 [${TARGET_DATE}] ===

参加率: ${RESPONDED}/${TOTAL} 人 (${PARTICIPATION_RATE}%)
回答済み: $(IFS=', '; echo "${RESPONDED_MEMBERS[*]:-なし}")
未回答: $(IFS=', '; echo "${NO_RESPONSE_MEMBERS[*]:-なし}")

【今日やること】
$(printf "%b" "${TODAY_ITEMS:-  （回答なし）\n}")
【ブロッカー】
$(printf "%b" "${BLOCKER_ITEMS:-  （ブロッカーなし）\n}")
集計時刻: ${SUMMARY_DATE}"

echo "$SUMMARY_TEXT"

# ── Webhook 送信 ──────────────────────────────────────────────
if [[ -z "$WEBHOOK_URL" ]]; then
  echo ""
  echo "INFO: WEBHOOK_URL が未設定のため送信をスキップします。"
  echo "      --webhook <URL> または環境変数 STANDUP_WEBHOOK_URL を設定してください。"
  exit 0
fi

# JSON ペイロード組み立て
RESPONDED_JSON="$(printf '%s\n' "${RESPONDED_MEMBERS[@]:-}" | jq -R . | jq -s . 2>/dev/null || echo '[]')"
NO_RESPONSE_JSON="$(printf '%s\n' "${NO_RESPONSE_MEMBERS[@]:-}" | jq -R . | jq -s . 2>/dev/null || echo '[]')"

PAYLOAD="$(cat <<EOF
{
  "date": "${TARGET_DATE}",
  "participation": {
    "responded": ${RESPONDED},
    "total": ${TOTAL},
    "rate_percent": ${PARTICIPATION_RATE},
    "responded_members": ${RESPONDED_JSON},
    "no_response_members": ${NO_RESPONSE_JSON}
  },
  "today_items": $(printf "%b" "${TODAY_ITEMS}" | jq -Rs . 2>/dev/null || echo '""'),
  "blockers": $(printf "%b" "${BLOCKER_ITEMS}" | jq -Rs . 2>/dev/null || echo '""'),
  "summary": $(echo "$SUMMARY_TEXT" | jq -Rs . 2>/dev/null || echo '""'),
  "generated_at": "${SUMMARY_DATE}"
}
EOF
)"

HTTP_STATUS=$(curl -s -o /tmp/team-summary-response.txt -w "%{http_code}" \
  -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" || echo "000")

if [[ "$HTTP_STATUS" =~ ^2 ]]; then
  echo ""
  echo "Webhook 送信成功 (HTTP ${HTTP_STATUS})"
else
  echo ""
  echo "ERROR: Webhook 送信失敗 (HTTP ${HTTP_STATUS})" >&2
  cat /tmp/team-summary-response.txt >&2 2>/dev/null || true
  exit 1
fi
