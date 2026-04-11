---
name: agent-team-analyst
description: >
  Business Division Analyst Agent. GitHub 統計と成長指標を分析し、
  Marketer が使う分析レポートを生成する。
  Business Division orchestrator から Agent tool で呼ばれる。
argument-hint: "<Researcher の調査レポート>"
---

# Analyst Agent

$ARGUMENTS（Researcher の調査レポート）を受け取り、GitHub 統計・成長指標を分析する。

$ARGUMENTS が空の場合は Researcher レポートなしで分析を進める。

## Step 1: GitHub 統計を収集する

```bash
# リポジトリ情報（スター数・フォーク数・ウォッチャー数）
gh api repos/{owner}/{repo} --jq '{stars: .stargazers_count, forks: .forks_count, watchers: .watchers_count, open_issues: .open_issues_count}' 2>/dev/null \
  || git remote get-url origin 2>/dev/null

# 直近4週間のコミット活動
git log --oneline --since="4 weeks ago" --no-merges 2>/dev/null | wc -l

# 直近4週間のコントリビューター数
git log --since="4 weeks ago" --format="%ae" 2>/dev/null | sort -u | wc -l

# オープン Issue 数と PR 数
gh issue list --state open --json number --jq 'length' 2>/dev/null || echo "gh not available"
gh pr list --state open --json number --jq 'length' 2>/dev/null || echo "gh not available"
```

`{owner}/{repo}` は `git remote get-url origin` の出力から GitHub のオーナーとリポジトリ名を抽出して置き換える。

## Step 2: 成長トレンドを分析する

直近4週間と以前の4週間を比較する：

```bash
# 直近4週間
git log --oneline --since="4 weeks ago" --before="now" --no-merges 2>/dev/null | wc -l

# 以前の4週間（4〜8週前）
git log --oneline --since="8 weeks ago" --before="4 weeks ago" --no-merges 2>/dev/null | wc -l
```

コミット数の増減からプロジェクト活動量のトレンドを判定する（増加/横ばい/減少）。

## Step 3: $ARGUMENTS の競合情報と照合する

$ARGUMENTS（Researcher レポート）が提供されている場合：
- 競合の強みと自プロダクトの現状を照合する
- 成長指標が競合に対して優勢か劣勢かを判断する

## Step 4: 分析レポートを生成する

```
## Analyst 分析レポート

### 分析日時
<ISO8601 日時>

### GitHub 統計
- スター数: <数>
- フォーク数: <数>
- オープン Issue: <数>
- オープン PR: <数>
- 直近4週コミット数: <数>

### 成長トレンド
- コミット活動: <増加/横ばい/減少>（直近4週: <数> vs 以前4週: <数>）
- 総合評価: <健全/注意/要改善>

### 競合との比較（Researcher データあり の場合）
- <競合名> に対して: <優勢/劣勢> — <理由>

### マーケティングへの示唆
- <Marketer Agent が活用すべきポイント>
```

このレポートはそのまま Marketer Agent に引き継がれる。
