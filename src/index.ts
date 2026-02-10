#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListResourcesRequestSchema,
  ListToolsRequestSchema,
  ReadResourceRequestSchema,
  ListPromptsRequestSchema,
  GetPromptRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { execSync } from "child_process";
import { existsSync } from "fs";
import { resolve, basename } from "path";

interface StandupInfo {
  repoName: string;
  branch: string;
  remoteUrl: string;
  sinceHours: number;
  commits: string;
  commitDetails: string;
  diffStat: string;
  diffContent: string;
  stagedDiff: string;
  openPRs: string;
  mergedPRs: string;
  reviewPRs: string;
}

/**
 * Execute a shell command and return the output
 */
function execCommand(command: string, cwd: string): string {
  try {
    return execSync(command, {
      cwd,
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"],
    }).trim();
  } catch (error) {
    return "";
  }
}

/**
 * Get since date string for git commands
 */
function getSinceDate(hours: number): string {
  const date = new Date();
  date.setHours(date.getHours() - hours);
  return date.toISOString();
}

/**
 * Collect standup information from a Git repository
 */
function collectStandupInfo(repoPath: string, sinceHours: number): StandupInfo {
  const absPath = resolve(repoPath);

  // Validate repository
  if (!existsSync(absPath)) {
    throw new Error(`Repository path does not exist: ${repoPath}`);
  }

  const gitDir = resolve(absPath, ".git");
  if (!existsSync(gitDir)) {
    throw new Error(`Not a git repository: ${repoPath}`);
  }

  const repoName = basename(execCommand("git rev-parse --show-toplevel", absPath));
  const branch = execCommand("git branch --show-current", absPath);
  const remoteUrl = execCommand("gh repo view --json url -q '.url'", absPath) || "Unknown";

  const sinceDate = getSinceDate(sinceHours);

  // Collect commit history
  const commits = execCommand(
    `git log --since="${sinceDate}" --oneline --no-merges`,
    absPath
  );

  const commitDetails = execCommand(
    `git log --since="${sinceDate}" --no-merges --stat --format="commit %h - %s (%ar)"`,
    absPath
  );

  // Collect diff information
  const diffStat = execCommand("git diff --stat", absPath);
  const diffContent = execCommand("git diff | head -200", absPath);
  const stagedDiff = execCommand("git diff --cached --stat", absPath);

  // Collect PR information (requires gh CLI)
  const openPRs = execCommand(
    'gh pr list --author="@me" --state=open --json number,title,updatedAt,url --template \'{{range .}}- #{{.number}} {{.title}} (更新: {{.updatedAt}})\\n  {{.url}}\\n{{end}}\'',
    absPath
  );

  const mergedPRs = execCommand(
    'gh pr list --author="@me" --state=merged --limit 5 --json number,title,mergedAt,url --template \'{{range .}}- #{{.number}} {{.title}} (マージ: {{.mergedAt}})\\n  {{.url}}\\n{{end}}\'',
    absPath
  );

  const reviewPRs = execCommand(
    'gh pr list --search "review-requested:@me" --state=open --json number,title,author,url --template \'{{range .}}- #{{.number}} {{.title}} (by {{.author.login}})\\n  {{.url}}\\n{{end}}\'',
    absPath
  );

  return {
    repoName,
    branch,
    remoteUrl,
    sinceHours,
    commits,
    commitDetails,
    diffStat,
    diffContent,
    stagedDiff,
    openPRs,
    mergedPRs,
    reviewPRs,
  };
}

/**
 * Format standup information as Markdown
 */
function formatStandupMarkdown(info: StandupInfo): string {
  const now = new Date().toLocaleString("ja-JP");

  let markdown = `# 📋 スタンドアップ情報: ${info.repoName}
- **日時**: ${now}
- **ブランチ**: ${info.branch}
- **リポジトリ**: ${info.remoteUrl}
- **集計期間**: 過去 ${info.sinceHours} 時間

---

## 📝 コミット履歴
`;

  if (!info.commits) {
    markdown += "直近のコミットはありません。\n";
  } else {
    markdown += "```\n" + info.commits + "\n```\n\n";
    markdown += "### 変更の詳細\n";
    markdown += "```\n" + info.commitDetails + "\n```\n";
  }

  markdown += "\n---\n\n## 🔀 コード差分（未コミットの変更）\n";

  if (!info.diffStat) {
    markdown += "未コミットの変更はありません。\n";
  } else {
    markdown += "```\n" + info.diffStat + "\n```\n\n";
    markdown += "### 差分の内容（先頭200行）\n";
    markdown += "```diff\n" + info.diffContent + "\n```\n";
  }

  if (info.stagedDiff) {
    markdown += "\n### ステージ済みの変更\n";
    markdown += "```\n" + info.stagedDiff + "\n```\n";
  }

  markdown += "\n---\n\n## 🔃 Pull Requests\n";
  markdown += "### オープン中のPR（自分）\n";
  markdown += info.openPRs || "オープン中のPRはありません。\n";
  markdown += "\n### 最近マージされたPR\n";
  markdown += info.mergedPRs || "最近マージされたPRはありません。\n";
  markdown += "\n### レビュー依頼されているPR\n";
  markdown += info.reviewPRs || "レビュー待ちのPRはありません。\n";

  markdown += "\n---\n\n> このサマリーを Claude の会話に貼り付けて、音声モードで朝会・夕会を始めましょう！\n";

  return markdown;
}

// Create MCP server
const server = new Server(
  {
    name: "朝会・夕会",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
      resources: {},
      prompts: {},
    },
  }
);

// Register Tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "collect_standup_info",
        description:
          "GitHub リポジトリから朝会・夕会用の情報を収集します。コミット履歴、差分、PR情報などを取得し、Markdown形式で返します。",
        inputSchema: {
          type: "object",
          properties: {
            repo_path: {
              type: "string",
              description: "Git リポジトリのパス（絶対パスまたは相対パス）",
            },
            since_hours: {
              type: "number",
              description: "何時間前からの情報を収集するか（デフォルト: 24時間）",
              default: 24,
            },
          },
          required: ["repo_path"],
        },
      },
    ],
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  if (request.params.name === "collect_standup_info") {
    const repoPath = String(request.params.arguments?.repo_path || ".");
    const sinceHours = Number(request.params.arguments?.since_hours || 24);

    try {
      const info = collectStandupInfo(repoPath, sinceHours);
      const markdown = formatStandupMarkdown(info);

      return {
        content: [
          {
            type: "text",
            text: markdown,
          },
        ],
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      return {
        content: [
          {
            type: "text",
            text: `エラーが発生しました: ${errorMessage}`,
          },
        ],
        isError: true,
      };
    }
  }

  throw new Error(`Unknown tool: ${request.params.name}`);
});

// Register Resources
server.setRequestHandler(ListResourcesRequestSchema, async () => {
  return {
    resources: [
      {
        uri: "standup://current",
        mimeType: "text/markdown",
        name: "Current Directory Standup Info",
        description: "現在のディレクトリのスタンドアップ情報（過去24時間）",
      },
    ],
  };
});

server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
  const uri = request.params.uri;

  if (uri === "standup://current") {
    try {
      const info = collectStandupInfo(".", 24);
      const markdown = formatStandupMarkdown(info);

      return {
        contents: [
          {
            uri,
            mimeType: "text/markdown",
            text: markdown,
          },
        ],
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      throw new Error(`スタンドアップ情報の取得に失敗しました: ${errorMessage}`);
    }
  }

  throw new Error(`Unknown resource: ${uri}`);
});

// Register Prompts
server.setRequestHandler(ListPromptsRequestSchema, async () => {
  return {
    prompts: [
      {
        name: "morning-standup",
        description: "朝会用のプロンプト。GitHub情報を元に今日の作業を計画します。",
        arguments: [
          {
            name: "repo_path",
            description: "Git リポジトリのパス",
            required: true,
          },
        ],
      },
      {
        name: "evening-standup",
        description: "夕会用のプロンプト。今日の作業を振り返ります。",
        arguments: [
          {
            name: "repo_path",
            description: "Git リポジトリのパス",
            required: true,
          },
          {
            name: "work_hours",
            description: "今日の作業時間（デフォルト: 10時間）",
            required: false,
          },
        ],
      },
    ],
  };
});

server.setRequestHandler(GetPromptRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  if (name === "morning-standup") {
    const repoPath = String(args?.repo_path || ".");
    const info = collectStandupInfo(repoPath, 24);
    const markdown = formatStandupMarkdown(info);

    return {
      description: "朝会用のプロンプトとGitHub情報",
      messages: [
        {
          role: "user",
          content: {
            type: "text",
            text: `おはようございます！今日の朝会を始めましょう。

以下は昨日からの作業状況です：

${markdown}

このGitHub情報を踏まえて：
1. 昨日の作業を簡潔にまとめてください
2. 今日の予定や目標について聞いてください
3. 困っていることや相談したいことを確認してください
4. 最後に今日のアクションアイテムを整理してください

音声モードで自然な会話として進めてください。`,
          },
        },
      ],
    };
  }

  if (name === "evening-standup") {
    const repoPath = String(args?.repo_path || ".");
    const workHours = Number(args?.work_hours || 10);
    const info = collectStandupInfo(repoPath, workHours);
    const markdown = formatStandupMarkdown(info);

    return {
      description: "夕会用のプロンプトとGitHub情報",
      messages: [
        {
          role: "user",
          content: {
            type: "text",
            text: `おつかれさまです！今日の振り返りをしましょう。

以下は今日の作業状況です：

${markdown}

このGitHub情報を踏まえて：
1. 今日の作業を要約してください
2. 今日の手応えについて聞いてください
3. 明日に持ち越すことを確認してください
4. 簡単な日報サマリーをまとめてください

音声モードで自然な会話として進めてください。`,
          },
        },
      ],
    };
  }

  throw new Error(`Unknown prompt: ${name}`);
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("朝会・夕会 MCP Server running on stdio");
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
