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

cat > "$OUTPUT_FILE" << EOF
# 📋 スタンドアップ情報: ${REPO_NAME}
- **日時**: $(date "+%Y-%m-%d %H:%M")
- **ブランチ**: ${BRANCH}
- **リポジトリ**: ${REMOTE_URL}
- **集計期間**: 過去 ${SINCE_HOURS} 時間

---

## 📝 コミット履歴
EOF

# --- コミット履歴 ---
COMMITS=$(git log --since="$SINCE_DATE" --oneline --no-merges 2>/dev/null || true)
if [ -z "$COMMITS" ]; then
  echo "直近のコミットはありません。" >> "$OUTPUT_FILE"
else
  echo '```' >> "$OUTPUT_FILE"
  echo "$COMMITS" >> "$OUTPUT_FILE"
  echo '```' >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"

  # 詳細（変更ファイル + stat）
  echo "### 変更の詳細" >> "$OUTPUT_FILE"
  echo '```' >> "$OUTPUT_FILE"
  git log --since="$SINCE_DATE" --no-merges --stat --format="commit %h - %s (%ar)" >> "$OUTPUT_FILE" 2>/dev/null || true
  echo '```' >> "$OUTPUT_FILE"
fi

# --- コードの差分サマリー ---
cat >> "$OUTPUT_FILE" << 'EOF'

---

## 🔀 コード差分（未コミットの変更）
EOF

DIFF_STAT=$(git diff --stat 2>/dev/null || true)
if [ -z "$DIFF_STAT" ]; then
  echo "未コミットの変更はありません。" >> "$OUTPUT_FILE"
else
  echo '```' >> "$OUTPUT_FILE"
  echo "$DIFF_STAT" >> "$OUTPUT_FILE"
  echo '```' >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  echo "### 差分の内容（先頭200行）" >> "$OUTPUT_FILE"
  echo '```diff' >> "$OUTPUT_FILE"
  git diff | head -200 >> "$OUTPUT_FILE" 2>/dev/null || true
  echo '```' >> "$OUTPUT_FILE"
fi

# --- ステージ済みの変更 ---
STAGED=$(git diff --cached --stat 2>/dev/null || true)
if [ -n "$STAGED" ]; then
  cat >> "$OUTPUT_FILE" << 'EOF'

### ステージ済みの変更
EOF
  echo '```' >> "$OUTPUT_FILE"
  echo "$STAGED" >> "$OUTPUT_FILE"
  echo '```' >> "$OUTPUT_FILE"
fi

# --- Pull Requests ---
cat >> "$OUTPUT_FILE" << 'EOF'

---

## 🔃 Pull Requests
EOF

# 自分が作成したオープンPR
echo "### オープン中のPR（自分）" >> "$OUTPUT_FILE"
MY_PRS=$(gh pr list --author="@me" --state=open --json number,title,updatedAt,url \
  --template '{{range .}}- #{{.number}} {{.title}} (更新: {{.updatedAt}}){{"\n"}}  {{.url}}{{"\n"}}{{end}}' 2>/dev/null || echo "取得できませんでした（gh CLI の認証を確認してください）")

if [ -z "$MY_PRS" ]; then
  echo "オープン中のPRはありません。" >> "$OUTPUT_FILE"
else
  echo "$MY_PRS" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"

# 最近マージされたPR
echo "### 最近マージされたPR" >> "$OUTPUT_FILE"
MERGED_PRS=$(gh pr list --author="@me" --state=merged --json number,title,mergedAt,url \
  --limit 5 \
  --template '{{range .}}- #{{.number}} {{.title}} (マージ: {{.mergedAt}}){{"\n"}}  {{.url}}{{"\n"}}{{end}}' 2>/dev/null || echo "取得できませんでした")

if [ -z "$MERGED_PRS" ]; then
  echo "最近マージされたPRはありません。" >> "$OUTPUT_FILE"
else
  echo "$MERGED_PRS" >> "$OUTPUT_FILE"
fi

# レビュー待ちのPR
echo "" >> "$OUTPUT_FILE"
echo "### レビュー依頼されているPR" >> "$OUTPUT_FILE"
REVIEW_PRS=$(gh pr list --search "review-requested:@me" --state=open --json number,title,author,url \
  --template '{{range .}}- #{{.number}} {{.title}} (by {{.author.login}}){{"\n"}}  {{.url}}{{"\n"}}{{end}}' 2>/dev/null || echo "取得できませんでした")

if [ -z "$REVIEW_PRS" ]; then
  echo "レビュー待ちのPRはありません。" >> "$OUTPUT_FILE"
else
  echo "$REVIEW_PRS" >> "$OUTPUT_FILE"
fi

# --- フッター ---
cat >> "$OUTPUT_FILE" << 'EOF'

---

> このサマリーを Claude の会話に貼り付けて、音声モードで朝会・夕会を始めましょう！
EOF

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
