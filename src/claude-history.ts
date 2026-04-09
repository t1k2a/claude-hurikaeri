import { existsSync, readdirSync, readFileSync } from "fs";
import { resolve, join } from "path";
import { homedir } from "os";

/**
 * Collect Claude conversation history for a given repo path.
 * @param repoPath - absolute or relative path to the git repository
 * @param sinceHours - how many hours back to look
 * @param baseDir - optional override for ~/.claude (used in tests)
 */
export function collectClaudeHistory(
  repoPath: string,
  sinceHours: number,
  baseDir: string = join(homedir(), ".claude")
): string {
  try {
    const absPath = resolve(repoPath);
    const projectDirName = absPath.replace(/\//g, "-");
    const claudeProjectsDir = join(baseDir, "projects", projectDirName);

    if (!existsSync(claudeProjectsDir)) {
      return "";
    }

    const sinceMs = Date.now() - sinceHours * 60 * 60 * 1000;
    const messages: string[] = [];

    const files = readdirSync(claudeProjectsDir).filter((f) => f.endsWith(".jsonl"));

    for (const file of files) {
      const filePath = join(claudeProjectsDir, file);
      const lines = readFileSync(filePath, "utf-8").split("\n").filter(Boolean);

      for (const line of lines) {
        try {
          const entry = JSON.parse(line);

          if (entry.type !== "user") continue;
          if (!entry.timestamp) continue;

          const entryMs = new Date(entry.timestamp).getTime();
          if (entryMs < sinceMs) continue;

          const content = entry.message?.content;
          if (!content || typeof content !== "string") continue;

          const trimmed = content.trim();
          if (trimmed.startsWith("/") || trimmed.length < 10) continue;

          messages.push(trimmed);
        } catch {
          // skip malformed lines
        }
      }
    }

    const unique = [...new Set(messages)];
    return unique.join("\n");
  } catch {
    return "";
  }
}
