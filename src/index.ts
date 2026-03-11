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
  diffStat: string;
  openIssues: string;
  openPRs: string;
  mergedPRs: string;
  reviewPRs: string;
  ghAvailable: boolean;
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
 * Check if a command is available
 */
function isCommandAvailable(command: string): boolean {
  try {
    execSync(`command -v ${command}`, {
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"],
    });
    return true;
  } catch (error) {
    return false;
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

  // Check if gh CLI is available
  const ghAvailable = isCommandAvailable("gh");
  let remoteUrl = "Unknown";
  let openIssues = "";
  let openPRs = "";
  let mergedPRs = "";
  let reviewPRs = "";

  if (ghAvailable) {
    remoteUrl = execCommand("gh repo view --json url -q '.url'", absPath) || "Unknown";
  } else {
    // Fallback: try to get remote URL from git config
    const gitRemote = execCommand("git config --get remote.origin.url", absPath);
    if (gitRemote) {
      remoteUrl = gitRemote;
    }
  }

  const sinceDate = getSinceDate(sinceHours);

  // Collect commit history (only messages)
  const commits = execCommand(
    `git log --since="${sinceDate}" --oneline --no-merges --format="%s"`,
    absPath
  );

  // Collect diff information (only stat to check if there are uncommitted changes)
  const diffStat = execCommand("git diff --stat", absPath);

  // Collect GitHub information (requires gh CLI)
  if (ghAvailable) {
    openIssues = execCommand(
      'gh issue list --assignee="@me" --state=open --json number,title --template \'{{range .}}- #{{.number}} {{.title}}\\n{{end}}\'',
      absPath
    );

    openPRs = execCommand(
      'gh pr list --author="@me" --state=open --json number,title --template \'{{range .}}- #{{.number}} {{.title}}\\n{{end}}\'',
      absPath
    );

    mergedPRs = execCommand(
      'gh pr list --author="@me" --state=merged --limit 5 --json number,title --template \'{{range .}}- #{{.number}} {{.title}}\\n{{end}}\'',
      absPath
    );

    reviewPRs = execCommand(
      'gh pr list --search "review-requested:@me" --state=open --json number,title,author --template \'{{range .}}- #{{.number}} {{.title}} (by {{.author.login}})\\n{{end}}\'',
      absPath
    );
  }

  return {
    repoName,
    branch,
    remoteUrl,
    sinceHours,
    commits,
    diffStat,
    openIssues,
    openPRs,
    mergedPRs,
    reviewPRs,
    ghAvailable,
  };
}

/**
 * Format standup information as Markdown
 */
function formatStandupMarkdown(info: StandupInfo): string {
  let markdown = "# 今日やったこと\n";

  // Add commits
  if (info.commits) {
    const commitLines = info.commits.split("\n").filter((line) => line.trim());
    commitLines.forEach((commit) => {
      markdown += `- ${commit}\n`;
    });
  }

  // Add merged PRs
  if (info.mergedPRs) {
    const prLines = info.mergedPRs.split("\n").filter((line) => line.trim());
    prLines.forEach((pr) => {
      markdown += `- ${pr}\n`;
    });
  }

  // Add uncommitted changes notice
  if (info.diffStat) {
    markdown += "- 作業中: 未コミットの変更あり\n";
  }

  // If nothing was done today
  if (!info.commits && !info.mergedPRs && !info.diffStat) {
    markdown += "- \n";
  }

  markdown += "\n# 明日やること\n";
  markdown += "- \n";
  markdown += "- \n";
  markdown += "- \n";

  // Add reference section only if there are open tasks
  const hasOpenTasks = info.openIssues || info.openPRs || info.reviewPRs;

  if (hasOpenTasks) {
    markdown += "\n---\n\n## 参考: オープン中のタスク\n";

    if (info.openIssues) {
      markdown += "### 自分のIssue\n";
      markdown += info.openIssues;
      markdown += "\n";
    }

    if (info.openPRs) {
      markdown += "### 自分のPR\n";
      markdown += info.openPRs;
      markdown += "\n";
    }

    if (info.reviewPRs) {
      markdown += "### レビュー待ちのPR\n";
      markdown += info.reviewPRs;
    }
  }

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
