import { execSync } from "child_process";
import { resolve } from "path";

function execCommand(command: string, cwd: string): string {
  try {
    return execSync(command, {
      cwd,
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"],
    }).trim();
  } catch {
    return "";
  }
}

/**
 * Collect git commits authored by the repo's configured user within sinceHours.
 */
export function collectGitCommits(repoPath: string, sinceHours: number): string {
  const absPath = resolve(repoPath);
  const authorEmail = execCommand("git config user.email", absPath);

  const since = new Date(Date.now() - sinceHours * 60 * 60 * 1000).toISOString();

  return execCommand(
    `git log --since="${since}" --oneline --no-merges --format="%s" --author="${authorEmail}"`,
    absPath
  );
}
