import { test, describe } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "fs";
import { tmpdir } from "os";
import { join } from "path";
import { execSync } from "child_process";
import { collectGitCommits } from "./git-history.js";

function makeTempRepo(): string {
  const dir = mkdtempSync(join(tmpdir(), "git-history-test-"));
  execSync("git init", { cwd: dir, stdio: "pipe" });
  execSync('git config user.email "me@example.com"', { cwd: dir, stdio: "pipe" });
  execSync('git config user.name "Me"', { cwd: dir, stdio: "pipe" });
  return dir;
}

function addCommit(repoDir: string, message: string, authorEmail: string, authorName: string): void {
  writeFileSync(join(repoDir, `${Date.now()}.txt`), message);
  execSync("git add -A", { cwd: repoDir, stdio: "pipe" });
  execSync(`git commit -m "${message}"`, {
    cwd: repoDir,
    stdio: "pipe",
    env: {
      ...process.env,
      GIT_AUTHOR_NAME: authorName,
      GIT_AUTHOR_EMAIL: authorEmail,
      GIT_COMMITTER_NAME: authorName,
      GIT_COMMITTER_EMAIL: authorEmail,
    },
  });
}

describe("collectGitCommits", () => {
  test("returns commits by the configured git user only", () => {
    const repo = makeTempRepo();
    try {
      addCommit(repo, "自分のコミット", "me@example.com", "Me");
      addCommit(repo, "他の人のコミット", "other@example.com", "Other");

      const result = collectGitCommits(repo, 24);
      assert.ok(result.includes("自分のコミット"), "自分のコミットが含まれていること");
      assert.ok(!result.includes("他の人のコミット"), "他の人のコミットが含まれていないこと");
    } finally {
      rmSync(repo, { recursive: true });
    }
  });

  test("returns empty string when there are no commits in the time range", () => {
    const repo = makeTempRepo();
    try {
      const result = collectGitCommits(repo, 0);
      assert.equal(result, "");
    } finally {
      rmSync(repo, { recursive: true });
    }
  });

  test("returns commits within sinceHours", () => {
    const repo = makeTempRepo();
    try {
      addCommit(repo, "最近のコミット", "me@example.com", "Me");

      const result = collectGitCommits(repo, 24);
      assert.ok(result.includes("最近のコミット"));
    } finally {
      rmSync(repo, { recursive: true });
    }
  });
});
