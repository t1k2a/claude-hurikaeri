#!/bin/bash

# GitHub Topics 設定スクリプト
# このスクリプトは GitHub CLI (gh) を使用してリポジトリに Topics を追加します

echo "📋 Setting GitHub Topics for claude-hurikaeri..."
echo ""

echo "Topics to add:"
echo "  - claude-code"
echo "  - claude-code-skill"
echo "  - standup"
echo "  - scrum"
echo "  - productivity"
echo "  - github"
echo "  - agile"
echo "  - daily-standup"
echo "  - automation"
echo "  - workflow"
echo ""

# GitHub API を使って Topics を設定
echo "Setting topics via GitHub API..."
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  repos/t1k2a/claude-hurikaeri/topics \
  --input - <<'EOF'
{
  "names": [
    "claude-code",
    "claude-code-skill",
    "standup",
    "scrum",
    "productivity",
    "github",
    "agile",
    "daily-standup",
    "automation",
    "workflow"
  ]
}
EOF

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Topics successfully set!"
  echo ""
  echo "View your repository:"
  echo "https://github.com/t1k2a/claude-hurikaeri"
else
  echo ""
  echo "❌ Failed to set topics"
  echo ""
  echo "Please set them manually at:"
  echo "https://github.com/t1k2a/claude-hurikaeri"
  echo ""
  echo "Or use the Web UI:"
  echo "1. Go to https://github.com/t1k2a/claude-hurikaeri"
  echo "2. Click the ⚙️ icon in the About section"
  echo "3. Add topics: claude-code, claude-code-skill, standup, scrum, productivity, github, agile, daily-standup, automation, workflow"
fi
