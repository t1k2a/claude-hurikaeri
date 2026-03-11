#!/bin/bash
# =============================================================
# 朝会・夕会用 GitHub 情報収集スクリプト
# 使い方: standup [リポジトリのパス]
# 出力:   ~/standup/<リポジトリ名>_<日付>.md（クリップボードにもコピー）
# 前提:   git, gh (GitHub CLI) がインストール済み
# =============================================================

set -euo pipefail

# --- 設定 ---
REPO_DIR="${1:-.}"                  # 引数なしなら現在ディレクトリ
SINCE_HOURS="${SINCE_HOURS:-24}"    # デフォルト24時間分
SINCE_DATE=$(date -v-${SINCE_HOURS}H "+%Y-%m-%dT%H:%M:%S" 2>/dev/null \
  || date -d "${SINCE_HOURS} hours ago" "+%Y-%m-%dT%H:%M:%S")

# 出力先: ~/standup/ に保存（リポジトリの中には出力しない）
OUTPUT_DIR="${STANDUP_DIR:-$HOME/standup}"
mkdir -p "$OUTPUT_DIR"

cd "$REPO_DIR"

# リポジトリ名を取得
REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
BRANCH=$(git branch --show-current)
REMOTE_URL=$(gh repo view --json url -q '.url' 2>/dev/null || echo "不明")

# ファイル名: リポジトリ名_日付.md
OUTPUT_FILE="${OUTPUT_DIR}/${REPO_NAME}_$(date '+%Y-%m-%d').md"

cat > "$OUTPUT_FILE" << 'EOF'
# 今日やったこと
EOF

# --- コミット履歴 ---
COMMITS=$(git log --since="$SINCE_DATE" --oneline --no-merges --format="%s" 2>/dev/null || true)
if [ -n "$COMMITS" ]; then
  echo "$COMMITS" | while IFS= read -r line; do
    echo "- $line" >> "$OUTPUT_FILE"
  done
fi

# --- マージされたPR ---
if command -v gh >/dev/null 2>&1; then
  MERGED_PRS=$(gh pr list --author="@me" --state=merged --limit 5 --json number,title \
    --template '{{range .}}- #{{.number}} {{.title}}{{"\n"}}{{end}}' 2>/dev/null || true)
  if [ -n "$MERGED_PRS" ]; then
    echo "$MERGED_PRS" >> "$OUTPUT_FILE"
  fi
fi

# --- 未コミットの変更 ---
DIFF_STAT=$(git diff --stat 2>/dev/null || true)
if [ -n "$DIFF_STAT" ]; then
  echo "- 作業中: 未コミットの変更あり" >> "$OUTPUT_FILE"
fi

# 何もない場合は空の箇条書き
if [ -z "$COMMITS" ] && [ -z "$MERGED_PRS" ] && [ -z "$DIFF_STAT" ]; then
  echo "- " >> "$OUTPUT_FILE"
fi

# --- 明日やること ---
cat >> "$OUTPUT_FILE" << 'EOF'

# 明日やること
-
-
-
EOF

# --- 参考: オープン中のタスク ---
if command -v gh >/dev/null 2>&1; then
  OPEN_ISSUES=$(gh issue list --assignee="@me" --state=open --json number,title \
    --template '{{range .}}- #{{.number}} {{.title}}{{"\n"}}{{end}}' 2>/dev/null || true)

  OPEN_PRS=$(gh pr list --author="@me" --state=open --json number,title \
    --template '{{range .}}- #{{.number}} {{.title}}{{"\n"}}{{end}}' 2>/dev/null || true)

  REVIEW_PRS=$(gh pr list --search "review-requested:@me" --state=open --json number,title,author \
    --template '{{range .}}- #{{.number}} {{.title}} (by {{.author.login}}){{"\n"}}{{end}}' 2>/dev/null || true)

  # 参考セクションを表示（データがある場合のみ）
  if [ -n "$OPEN_ISSUES" ] || [ -n "$OPEN_PRS" ] || [ -n "$REVIEW_PRS" ]; then
    cat >> "$OUTPUT_FILE" << 'EOF'

---

## 参考: オープン中のタスク
EOF

    if [ -n "$OPEN_ISSUES" ]; then
      echo "### 自分のIssue" >> "$OUTPUT_FILE"
      echo "$OPEN_ISSUES" >> "$OUTPUT_FILE"
      echo "" >> "$OUTPUT_FILE"
    fi

    if [ -n "$OPEN_PRS" ]; then
      echo "### 自分のPR" >> "$OUTPUT_FILE"
      echo "$OPEN_PRS" >> "$OUTPUT_FILE"
      echo "" >> "$OUTPUT_FILE"
    fi

    if [ -n "$REVIEW_PRS" ]; then
      echo "### レビュー待ちのPR" >> "$OUTPUT_FILE"
      echo "$REVIEW_PRS" >> "$OUTPUT_FILE"
    fi
  fi
fi

# --- クリップボードにコピー ---
if command -v pbcopy &>/dev/null; then
  cat "$OUTPUT_FILE" | pbcopy
  echo "✅ $OUTPUT_FILE を生成し、クリップボードにコピーしました"
elif command -v xclip &>/dev/null; then
  cat "$OUTPUT_FILE" | xclip -selection clipboard
  echo "✅ $OUTPUT_FILE を生成し、クリップボードにコピーしました"
else
  echo "✅ $OUTPUT_FILE を生成しました（手動でコピーしてください）"
fi

echo "📄 ファイル: $OUTPUT_FILE"
