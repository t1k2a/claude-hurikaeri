import { test, describe } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from "fs";
import { tmpdir } from "os";
import { join } from "path";
import { collectClaudeHistory } from "./claude-history.js";

function makeTempDir(): string {
  return mkdtempSync(join(tmpdir(), "claude-history-test-"));
}

function writeJsonl(dir: string, filename: string, entries: object[]): void {
  const content = entries.map((e) => JSON.stringify(e)).join("\n") + "\n";
  writeFileSync(join(dir, filename), content, "utf-8");
}

function now(): string {
  return new Date().toISOString();
}

function hoursAgo(n: number): string {
  return new Date(Date.now() - n * 60 * 60 * 1000).toISOString();
}

describe("collectClaudeHistory", () => {
  let baseDir: string;

  // Setup and teardown per test would be cleaner, but node:test doesn't have beforeEach
  // so we create a fresh temp dir per test inline

  test("returns empty string when project directory does not exist", () => {
    const base = makeTempDir();
    try {
      const result = collectClaudeHistory("/no/such/project", 24, base);
      assert.equal(result, "");
    } finally {
      rmSync(base, { recursive: true });
    }
  });

  test("returns empty string when no JSONL files exist", () => {
    const base = makeTempDir();
    try {
      const projectDir = join(base, "projects", "-home-joji-myrepo");
      mkdirSync(projectDir, { recursive: true });
      const result = collectClaudeHistory("/home/joji/myrepo", 24, base);
      assert.equal(result, "");
    } finally {
      rmSync(base, { recursive: true });
    }
  });

  test("extracts user messages from JSONL within time range", () => {
    const base = makeTempDir();
    try {
      const projectDir = join(base, "projects", "-home-joji-myrepo");
      mkdirSync(projectDir, { recursive: true });
      writeJsonl(projectDir, "session1.jsonl", [
        {
          type: "user",
          timestamp: now(),
          message: { role: "user", content: "新機能を追加してほしい" },
        },
      ]);

      const result = collectClaudeHistory("/home/joji/myrepo", 24, base);
      assert.equal(result, "新機能を追加してほしい");
    } finally {
      rmSync(base, { recursive: true });
    }
  });

  test("ignores messages older than sinceHours", () => {
    const base = makeTempDir();
    try {
      const projectDir = join(base, "projects", "-home-joji-myrepo");
      mkdirSync(projectDir, { recursive: true });
      writeJsonl(projectDir, "session1.jsonl", [
        {
          type: "user",
          timestamp: hoursAgo(25), // 25時間前 = 対象外
          message: { role: "user", content: "古いメッセージです" },
        },
      ]);

      const result = collectClaudeHistory("/home/joji/myrepo", 24, base);
      assert.equal(result, "");
    } finally {
      rmSync(base, { recursive: true });
    }
  });

  test("ignores non-user type entries", () => {
    const base = makeTempDir();
    try {
      const projectDir = join(base, "projects", "-home-joji-myrepo");
      mkdirSync(projectDir, { recursive: true });
      writeJsonl(projectDir, "session1.jsonl", [
        {
          type: "assistant",
          timestamp: now(),
          message: { role: "assistant", content: "はい、実装します" },
        },
        {
          type: "file-history-snapshot",
          timestamp: now(),
          snapshot: {},
        },
      ]);

      const result = collectClaudeHistory("/home/joji/myrepo", 24, base);
      assert.equal(result, "");
    } finally {
      rmSync(base, { recursive: true });
    }
  });

  test("ignores slash commands", () => {
    const base = makeTempDir();
    try {
      const projectDir = join(base, "projects", "-home-joji-myrepo");
      mkdirSync(projectDir, { recursive: true });
      writeJsonl(projectDir, "session1.jsonl", [
        {
          type: "user",
          timestamp: now(),
          message: { role: "user", content: "/standup" },
        },
        {
          type: "user",
          timestamp: now(),
          message: { role: "user", content: "通常のメッセージです" },
        },
      ]);

      const result = collectClaudeHistory("/home/joji/myrepo", 24, base);
      assert.equal(result, "通常のメッセージです");
    } finally {
      rmSync(base, { recursive: true });
    }
  });

  test("ignores messages shorter than 10 characters", () => {
    const base = makeTempDir();
    try {
      const projectDir = join(base, "projects", "-home-joji-myrepo");
      mkdirSync(projectDir, { recursive: true });
      writeJsonl(projectDir, "session1.jsonl", [
        {
          type: "user",
          timestamp: now(),
          message: { role: "user", content: "ok" },
        },
        {
          type: "user",
          timestamp: now(),
          message: { role: "user", content: "これは長いメッセージです" },
        },
      ]);

      const result = collectClaudeHistory("/home/joji/myrepo", 24, base);
      assert.equal(result, "これは長いメッセージです");
    } finally {
      rmSync(base, { recursive: true });
    }
  });

  test("deduplicates identical messages", () => {
    const base = makeTempDir();
    try {
      const projectDir = join(base, "projects", "-home-joji-myrepo");
      mkdirSync(projectDir, { recursive: true });
      writeJsonl(projectDir, "session1.jsonl", [
        {
          type: "user",
          timestamp: now(),
          message: { role: "user", content: "同じメッセージが重複しています" },
        },
        {
          type: "user",
          timestamp: now(),
          message: { role: "user", content: "同じメッセージが重複しています" },
        },
      ]);

      const result = collectClaudeHistory("/home/joji/myrepo", 24, base);
      assert.equal(result, "同じメッセージが重複しています");
    } finally {
      rmSync(base, { recursive: true });
    }
  });

  test("collects messages from multiple JSONL files", () => {
    const base = makeTempDir();
    try {
      const projectDir = join(base, "projects", "-home-joji-myrepo");
      mkdirSync(projectDir, { recursive: true });
      writeJsonl(projectDir, "session1.jsonl", [
        {
          type: "user",
          timestamp: now(),
          message: { role: "user", content: "セッション1のメッセージ" },
        },
      ]);
      writeJsonl(projectDir, "session2.jsonl", [
        {
          type: "user",
          timestamp: now(),
          message: { role: "user", content: "セッション2のメッセージ" },
        },
      ]);

      const result = collectClaudeHistory("/home/joji/myrepo", 24, base);
      const lines = result.split("\n").filter(Boolean);
      assert.equal(lines.length, 2);
      assert.ok(lines.includes("セッション1のメッセージ"));
      assert.ok(lines.includes("セッション2のメッセージ"));
    } finally {
      rmSync(base, { recursive: true });
    }
  });
});
