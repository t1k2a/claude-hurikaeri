#!/usr/bin/env bash
# dashboard.sh — スタンドアップ履歴の可視化ダッシュボード（静的HTML）生成
# Usage: bash skills/standup/dashboard.sh [--days N] [--out <path>]
#
# 引数:
#   --days N       過去 N 日分を表示（デフォルト: 30）
#   --out <path>   出力 HTML ファイルパス（デフォルト: ./standup-dashboard-<timestamp>.html）

set -eo pipefail

# --- 引数解析 ---
DAYS=30
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUT_FILE="standup-dashboard-${TIMESTAMP}.html"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --days)
      DAYS="$2"
      shift 2
      ;;
    --out)
      OUT_FILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: bash dashboard.sh [--days N] [--out <path>]" >&2
      exit 1
      ;;
  esac
done

HISTORY_DIR="${HOME}/.standup-history"

# --- 履歴ディレクトリ確認 ---
if [[ ! -d "$HISTORY_DIR" ]]; then
  echo "No standup history found at ${HISTORY_DIR}. Creating empty dashboard." >&2
  HISTORY_FILES=()
else
  # 過去 DAYS 日分のファイルを取得
  SINCE=$(date -d "-${DAYS} days" +%Y-%m-%d 2>/dev/null || date -v "-${DAYS}d" +%Y-%m-%d 2>/dev/null || echo "1970-01-01")
  mapfile -t HISTORY_FILES < <(
    find "$HISTORY_DIR" -maxdepth 1 -name "*.json" | sort -r
  )
fi

# --- 集計 ---
declare -A DAY_COUNT   # date -> count
declare -A REPO_COUNT  # repo -> count
declare -A MODE_COUNT  # morning/evening -> count
TOTAL=0
declare -a DATES_JS
declare -a COUNTS_JS
declare -a REPOS_JS
declare -a REPO_COUNTS_JS

for f in "${HISTORY_FILES[@]}"; do
  fname=$(basename "$f")
  # ファイル名形式: YYYY-MM-DD-morning-<repo>.json
  date_part=$(echo "$fname" | grep -oP '^\d{4}-\d{2}-\d{2}' 2>/dev/null || echo "")
  [[ -z "$date_part" ]] && continue
  [[ "$date_part" < "$SINCE" ]] && continue

  mode_part=$(echo "$fname" | sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-//' | cut -d'-' -f1)
  repo_part=$(echo "$fname" | sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-[a-z]*-//' | sed 's/\.json$//')

  DAY_COUNT["$date_part"]=$(( ${DAY_COUNT["$date_part"]:-0} + 1 ))
  REPO_COUNT["$repo_part"]=$(( ${REPO_COUNT["$repo_part"]:-0} + 1 ))
  MODE_COUNT["$mode_part"]=$(( ${MODE_COUNT["$mode_part"]:-0} + 1 ))
  TOTAL=$(( TOTAL + 1 ))
done

# JavaScript 用データ生成（日付別カウント）
DATE_LABELS=""
DATE_DATA=""
for d in $(echo "${!DAY_COUNT[@]}" | tr ' ' '\n' | sort); do
  DATE_LABELS="${DATE_LABELS}\"${d}\","
  DATE_DATA="${DATE_DATA}${DAY_COUNT[$d]},"
done
DATE_LABELS="${DATE_LABELS%,}"
DATE_DATA="${DATE_DATA%,}"

# リポジトリ別ラベルとデータ
REPO_LABELS=""
REPO_DATA=""
for r in "${!REPO_COUNT[@]}"; do
  REPO_LABELS="${REPO_LABELS}\"${r}\","
  REPO_DATA="${REPO_DATA}${REPO_COUNT[$r]},"
done
REPO_LABELS="${REPO_LABELS%,}"
REPO_DATA="${REPO_DATA%,}"

MORNING_COUNT=${MODE_COUNT["morning"]:-0}
EVENING_COUNT=${MODE_COUNT["evening"]:-0}

# --- HTML 生成 ---
cat > "$OUT_FILE" <<HTML
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>スタンドアップ ダッシュボード</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4/dist/chart.umd.min.js"></script>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #f5f7fa;
      color: #333;
      line-height: 1.6;
    }
    header {
      background: #2c3e50;
      color: #fff;
      padding: 20px 32px;
    }
    header h1 { font-size: 1.4rem; font-weight: 600; }
    header .meta { font-size: 0.8rem; color: #95a5a6; margin-top: 4px; }
    main { max-width: 1100px; margin: 32px auto; padding: 0 20px; }
    .cards {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 16px;
      margin-bottom: 32px;
    }
    .card {
      background: #fff;
      border-radius: 10px;
      padding: 20px;
      box-shadow: 0 1px 4px rgba(0,0,0,.08);
      text-align: center;
    }
    .card .num { font-size: 2.2rem; font-weight: 700; color: #3498db; }
    .card .label { font-size: 0.82rem; color: #7f8c8d; margin-top: 4px; }
    .charts {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 20px;
      margin-bottom: 32px;
    }
    @media (max-width: 700px) { .charts { grid-template-columns: 1fr; } }
    .chart-box {
      background: #fff;
      border-radius: 10px;
      padding: 20px;
      box-shadow: 0 1px 4px rgba(0,0,0,.08);
    }
    .chart-box h2 {
      font-size: 0.95rem;
      color: #34495e;
      margin-bottom: 16px;
      font-weight: 600;
    }
    .chart-box.wide {
      grid-column: 1 / -1;
    }
    footer {
      text-align: center;
      color: #bdc3c7;
      font-size: 0.78rem;
      padding: 20px 0 40px;
    }
  </style>
</head>
<body>
<header>
  <h1>スタンドアップ ダッシュボード</h1>
  <div class="meta">生成日時: $(date "+%Y-%m-%d %H:%M:%S") &nbsp;|&nbsp; 対象: 過去 ${DAYS} 日間</div>
</header>
<main>
  <div class="cards">
    <div class="card">
      <div class="num">${TOTAL}</div>
      <div class="label">総スタンドアップ数</div>
    </div>
    <div class="card">
      <div class="num">${MORNING_COUNT}</div>
      <div class="label">朝会（morning）</div>
    </div>
    <div class="card">
      <div class="num">${EVENING_COUNT}</div>
      <div class="label">夕会（evening）</div>
    </div>
    <div class="card">
      <div class="num">${#REPO_COUNT[@]}</div>
      <div class="label">対象リポジトリ数</div>
    </div>
  </div>

  <div class="charts">
    <div class="chart-box wide">
      <h2>日別スタンドアップ回数（過去 ${DAYS} 日）</h2>
      <canvas id="dailyChart" height="90"></canvas>
    </div>
    <div class="chart-box">
      <h2>リポジトリ別スタンドアップ数</h2>
      <canvas id="repoChart"></canvas>
    </div>
    <div class="chart-box">
      <h2>朝会 / 夕会 比率</h2>
      <canvas id="modeChart"></canvas>
    </div>
  </div>
</main>
<footer>
  claude-hurikaeri standup dashboard &mdash; generated by dashboard.sh
</footer>
<script>
const COLORS = ['#3498db','#2ecc71','#e74c3c','#f39c12','#9b59b6','#1abc9c','#e67e22','#34495e'];

// 日別グラフ
new Chart(document.getElementById('dailyChart'), {
  type: 'bar',
  data: {
    labels: [${DATE_LABELS}],
    datasets: [{
      label: 'スタンドアップ回数',
      data: [${DATE_DATA}],
      backgroundColor: '#3498db',
      borderRadius: 4,
    }]
  },
  options: {
    plugins: { legend: { display: false } },
    scales: { y: { beginAtZero: true, ticks: { stepSize: 1 } } }
  }
});

// リポジトリ別グラフ
new Chart(document.getElementById('repoChart'), {
  type: 'bar',
  data: {
    labels: [${REPO_LABELS}],
    datasets: [{
      label: 'スタンドアップ数',
      data: [${REPO_DATA}],
      backgroundColor: COLORS,
      borderRadius: 4,
    }]
  },
  options: {
    indexAxis: 'y',
    plugins: { legend: { display: false } },
    scales: { x: { beginAtZero: true, ticks: { stepSize: 1 } } }
  }
});

// 朝会/夕会 比率
new Chart(document.getElementById('modeChart'), {
  type: 'doughnut',
  data: {
    labels: ['朝会', '夕会'],
    datasets: [{
      data: [${MORNING_COUNT}, ${EVENING_COUNT}],
      backgroundColor: ['#3498db', '#e67e22'],
    }]
  },
  options: {
    plugins: { legend: { position: 'bottom' } }
  }
});
</script>
</body>
</html>
HTML

echo "Dashboard generated: ${OUT_FILE}"
