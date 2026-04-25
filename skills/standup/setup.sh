#!/usr/bin/env bash
# setup.sh — claude-hurikaeri standup スキル 初回セットアップウィザード
#
# 使い方:
#   bash skills/standup/setup.sh
#
# このスクリプトは以下を対話形式でガイドします:
#   1. Webhook URL の設定（Slack / Discord）
#   2. デフォルトリポジトリパスの設定
#   3. シェル設定ファイル（~/.bashrc または ~/.zshrc）への環境変数追記

set -euo pipefail

# --- ユーティリティ ---
info()    { echo "[INFO] $*"; }
success() { echo "[OK]   $*"; }
warn()    { echo "[WARN] $*"; }
error()   { echo "[ERROR] $*" >&2; }

echo ""
echo "============================================="
echo " claude-hurikaeri standup セットアップウィザード"
echo "============================================="
echo ""
echo "このウィザードは初回セットアップを対話形式でガイドします。"
echo "設定はいつでも ~/.bashrc / ~/.zshrc を編集して変更できます。"
echo ""

# --- Step 1: シェル設定ファイルの選択 ---
SHELL_RC=""
if [ -f "$HOME/.zshrc" ] && [ "${SHELL:-}" != "/bin/bash" ]; then
  SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
  SHELL_RC="$HOME/.bashrc"
else
  SHELL_RC="$HOME/.bashrc"
fi

info "設定ファイル: $SHELL_RC"
echo ""

# --- Step 2: Webhook URL の設定 ---
echo "--- Webhook URL の設定 ---"
echo "Slack または Discord の Webhook URL を入力してください。"
echo "（Webhook を使わない場合は Enter を押してスキップ）"
echo ""

EXISTING_WEBHOOK="${STANDUP_WEBHOOK_URL:-}"
if [ -n "$EXISTING_WEBHOOK" ]; then
  info "現在の設定: STANDUP_WEBHOOK_URL は既に設定済みです。"
  echo -n "新しい Webhook URL（変更しない場合は Enter）: "
else
  echo -n "Webhook URL: "
fi

read -r INPUT_WEBHOOK

if [ -n "$INPUT_WEBHOOK" ]; then
  # 簡易バリデーション
  if [[ "$INPUT_WEBHOOK" != https://* ]]; then
    warn "URL が https:// で始まっていません。続行しますが、確認してください。"
  fi
  WEBHOOK_URL="$INPUT_WEBHOOK"
elif [ -n "$EXISTING_WEBHOOK" ]; then
  WEBHOOK_URL="$EXISTING_WEBHOOK"
  info "既存の Webhook URL を使用します。"
else
  WEBHOOK_URL=""
  warn "Webhook URL がスキップされました。--notify オプションは使用できません。"
fi

echo ""

# --- Step 3: デフォルトリポジトリパスの設定 ---
echo "--- デフォルトリポジトリパスの設定 ---"
echo "スタンドアップで使用するリポジトリのパスを入力してください。"
echo "（デフォルト: 現在のディレクトリ '.' を使用）"
echo ""

EXISTING_REPO="${STANDUP_DEFAULT_REPO:-}"
if [ -n "$EXISTING_REPO" ]; then
  info "現在の設定: STANDUP_DEFAULT_REPO=$EXISTING_REPO"
  echo -n "新しいリポジトリパス（変更しない場合は Enter）: "
else
  echo -n "リポジトリパス（Enter でスキップ）: "
fi

read -r INPUT_REPO

if [ -n "$INPUT_REPO" ]; then
  if [ ! -d "$INPUT_REPO" ]; then
    warn "ディレクトリが見つかりません: $INPUT_REPO"
    warn "パスは保存されますが、実行時にエラーになる可能性があります。"
  fi
  REPO_PATH="$INPUT_REPO"
elif [ -n "$EXISTING_REPO" ]; then
  REPO_PATH="$EXISTING_REPO"
  info "既存のリポジトリパスを使用します。"
else
  REPO_PATH=""
  info "リポジトリパスはスキップされました。実行時に引数で指定してください。"
fi

echo ""

# --- Step 4: 設定ファイルへの書き込み ---
MARKER="# === claude-hurikaeri standup 設定 ==="
SETTINGS_BLOCK="$MARKER"

if [ -n "$WEBHOOK_URL" ]; then
  SETTINGS_BLOCK="${SETTINGS_BLOCK}
export STANDUP_WEBHOOK_URL='${WEBHOOK_URL}'"
fi

if [ -n "$REPO_PATH" ]; then
  SETTINGS_BLOCK="${SETTINGS_BLOCK}
export STANDUP_DEFAULT_REPO='${REPO_PATH}'"
fi

SETTINGS_BLOCK="${SETTINGS_BLOCK}
# =================================="

# 既存の設定ブロックを確認
if grep -q "$MARKER" "$SHELL_RC" 2>/dev/null; then
  warn "既存の設定ブロックが $SHELL_RC に見つかりました。"
  echo -n "上書きしますか？ [y/N]: "
  read -r OVERWRITE
  if [[ "$OVERWRITE" =~ ^[Yy]$ ]]; then
    # 既存ブロックを削除して再追記
    TMPFILE=$(mktemp)
    # マーカー行から次の区切り行までを除去
    awk "/$MARKER/,/^# ==================================/" "$SHELL_RC" > /dev/null
    grep -v "$MARKER" "$SHELL_RC" | grep -v "STANDUP_WEBHOOK_URL" | grep -v "STANDUP_DEFAULT_REPO" | grep -v "^# ==================================" > "$TMPFILE" || true
    cp "$TMPFILE" "$SHELL_RC"
    rm -f "$TMPFILE"
    success "既存の設定を削除しました。"
  else
    warn "上書きをスキップしました。手動で $SHELL_RC を編集してください。"
    echo ""
    echo "追記すべき設定:"
    echo "$SETTINGS_BLOCK"
    echo ""
    exit 0
  fi
fi

if [ -n "$WEBHOOK_URL" ] || [ -n "$REPO_PATH" ]; then
  echo "" >> "$SHELL_RC"
  echo "$SETTINGS_BLOCK" >> "$SHELL_RC"
  success "$SHELL_RC に設定を追記しました。"
else
  info "書き込む設定がないため、ファイルへの追記をスキップしました。"
fi

echo ""

# --- Step 5: 動作確認ガイド ---
echo "--- セットアップ完了 ---"
echo ""
echo "設定を反映するには以下を実行してください:"
echo "  source $SHELL_RC"
echo ""
echo "スタンドアップを試すには:"
echo "  /standup morning          # 朝会"
echo "  /standup evening          # 夕会"
if [ -n "$WEBHOOK_URL" ]; then
  echo "  /standup morning --notify  # Webhook 送信付き朝会"
fi
echo ""

# --- Step 6: 前提条件チェック ---
echo "--- 前提条件チェック ---"
echo ""

if command -v git >/dev/null 2>&1; then
  GIT_VER=$(git --version 2>&1 | head -1)
  success "git: $GIT_VER"
else
  error "git がインストールされていません。インストールしてください。"
fi

if command -v gh >/dev/null 2>&1; then
  GH_VER=$(gh --version 2>&1 | head -1)
  success "gh (GitHub CLI): $GH_VER"
  # 認証チェック
  if gh auth status >/dev/null 2>&1; then
    success "gh: 認証済み"
  else
    warn "gh: 未認証。PR/Issue 取得には 'gh auth login' が必要です。"
  fi
else
  warn "gh (GitHub CLI) が見つかりません。PR/Issue 情報の取得にはインストールが推奨されます。"
  warn "  インストール: brew install gh  または  https://cli.github.com/"
fi

if command -v curl >/dev/null 2>&1; then
  success "curl: $(curl --version 2>&1 | head -1)"
else
  warn "curl が見つかりません。--notify オプションには curl が必要です。"
fi

echo ""
echo "セットアップが完了しました。"
echo "詳細は README.md または skills/standup/SKILL.md を参照してください。"
echo ""
