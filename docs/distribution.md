# Dev Rewind: distribution candidate

Prepared 2026-10-12. This is a review candidate, not a published marketplace release.

## Product identity and rename

| Surface | Decision |
|---|---|
| Display brand | Dev Rewind |
| Subtitle | Plan your day. Reflect on your work. |
| New Skill folder/frontmatter | dev-rewind (lowercase hyphenated, matching folder) |
| New command | /dev-rewind in hosts with slash-command skills |
| Legacy command | /standup alias; install standup and dev-rewind side by side |
| GitHub repository | t1k2a/claude-hurikaeri unchanged |
| npm package/bin | claude-hurikaeri-mcp unchanged; separate implementation |
| Existing root package.json | claude-hurikaeri unchanged; no release/version change |
| History and notification variables | .standup-history and STANDUP_* unchanged |
| Claude plugin ID | No .claude-plugin/plugin.json or marketplace manifest in inspected public main; no ID to migrate |

The alias preserves the invocation, not the old single-folder installation procedure.
Users updating an existing standalone standup installation must install both folders.
Old helpers are retained unchanged and excluded from the new ZIP.
No repository rename, npm publication, package-name reservation, trademark clearance or marketplace upload has occurred.

## Existing formats verified

Public main inspected: 39428d1c8f90d64f7507ef127e1e06ae36aa5d69.
It contains a Markdown Skill, Shell helpers and a metadata-only package.json (no runtime dependencies).
The installed/local checkout was older and had user changes; it was not edited or packaged.
A separate Windows checkout was used. Its sparse checkout excludes .github because upstream has a
CODEOWNERS filename ending in a space. The Git tree retains that file unchanged.

npm registry metadata and `npm pack claude-hurikaeri-mcp@1.0.0 --ignore-scripts` show a different artifact:
Node >=18, compiled build/index.js, README, system_prompt and package.json.
The tarball has seven files, no SKILL.md, no Claude plugin manifest, and no LICENSE file.
Its package.json declares MIT and @modelcontextprotocol/sdk ^1.0.4.
The registry points to the same GitHub repository, but that does not make current main and npm equivalent. SDK 1.0.4 registry metadata declares MIT; its transitive dependencies were not installed or audited.
Tarball shasum: 3878025641378a3fb86310f74d3c9f39edab0a4a.
Only metadata/source/syntax were inspected; the MCP server was not installed or run.

## Package and license inventory

ZIP contains exactly:
- dev-rewind/SKILL.md
- dev-rewind/README.md
- dev-rewind/default-template.md
- dev-rewind/references/optional-operations.md
- dev-rewind/examples/synthetic-session.md
- dev-rewind/LICENSE (byte-for-byte root MIT license, copyright 2026 t1k2a)

No runtime libraries, binaries, third-party source or npm dependencies are bundled.
Git and optional gh are external tools. The packaging script uses only Python's standard library and
is not shipped inside the Skill ZIP. Thus there are no bundled dependency notices to aggregate for this ZIP.
The separate MCP's direct SDK license metadata was checked separately; transitive licenses and the
missing LICENSE in its tarball remain outside this candidate's scope. Do not redistribute the MCP from this ZIP.

Agensi's buyer terms reportedly differ from MIT redistribution permissions. Keep the existing MIT license;
resolve that terms/licensing compatibility before uploading. Pricing, payment onboarding/Stripe requirements,
account connection and new contracts are pending with the owner. This document does not grant approval for them.

## Listing copy (draft, price unset)

**Title:** Dev Rewind — Git-based daily planning and reflection

**Short description:**
Turn your Git activity into a focused morning plan or evening retrospective. A Japanese-first Agent Skill
with optional GitHub context, clear next steps, and no automatic publishing.

**Description:**
Start your day with a clearer plan and finish it with a short reflection. Dev Rewind helps a compatible
coding agent review recent Git commits and change summaries, ask one question at a time, and produce a
concise Markdown standup report.

Use it for personal development check-ins: morning planning, evening reflection, and explicit searches
of reports you chose to save. GitHub PR and Issue context is optional and requires an authenticated gh CLI.
The default workflow reads only the selected repository and replies in your conversation. Saving reports,
HTML export, and external notifications require explicit requests and suitable host tools.

Includes the Skill, setup guide, optional-operation reference, output template, one fully synthetic
Japanese example, and the original MIT license. No MCP server, Node.js package, paid integration,
local model, or WSL installation is bundled or required by the core workflow.

Windows Git command checks and packaging tests are documented. Full end-to-end testing across Claude Code,
Codex and Gemini CLI, and live Slack/Discord/Chatwork delivery, have not been completed. The instructions
are designed for agents with local command access; availability depends on the host's tools and permissions.
Your AI provider's own usage fees and data policies still apply.

**日本語紹介:**
Gitの記録を見ながら、朝に今日の予定を、夕方に次の一歩を整理するスキルです。
作業の根拠と本人の予定を分け、一問ずつ会話して短いレポートにまとめます。
既定では保存・通知をせず、必要な場合だけ追加操作を依頼できます。

**Suggested category/tags:** Developer productivity; git, standup, retrospective, planning, Japanese.
**Price:** undecided; do not silently select a paid listing or accept marketplace terms.

## Verification record

Baseline scenario evaluation of the old Skill found:
- Bash-only commands on PowerShell; morning plans put under a tomorrow heading.
- Automatic clipboard mutation; unescaped quote interpolation into Shell report assignments.
- REPORT/STANDUP_REPORT mismatch and raw HTML insertion.
- Duplicate step numbering and ambiguous option-value parsing.

The revised Skill separates core workflow and optional operations, supplies shell-neutral Git invocations,
keeps unknown plans explicit, treats source text as data, requires escaped HTML, and keeps side effects opt-in.

Automated tests exercise a synthetic repository with a space in its path, staged/unstaged/untracked files,
empty/non-Git paths, and a fake secret file whose body must not appear in collection output.
ZIP tests verify a fixed file list, exact license inclusion, exclusion of fake private files/.env/binaries,
missing-file failure without partial output, and refusal to overwrite an existing archive.

Behavioral scenarios are simulated by a separate agent; they are not full client integration tests.
GitHub auth/network failure is documented; this environment's gh was not logged in, so live PR collection
was not run. No real conversation, private work data, account tokens or notification destinations were used.
Final results: 5/5 unittest checks passed; all four existing Shell scripts passed bash -n; the published MCP build/index.js passed node --check; git diff --check passed. Four behavioral simulations passed (PowerShell without gh, HTML special characters, history-only with webhook configured, and untrusted template instructions). A follow-up review confirmed the legacy install instructions; a CRLF-sensitive test assertion was corrected and all five tests rerun successfully. No remaining blocking code findings were reported in that review.

## Reproduction

```text
python -m unittest discover -s tests -v
python scripts/package_skill.py --output ../dev-rewind-skill.zip
git diff --check
```

Use a new output filename for each rebuild. Run bash -n against existing .sh files using an existing
Git Bash installation if available. Do not install WSL or a model just to validate this text package.

Installation references checked: [Claude Code](https://code.claude.com/docs/en/skills),
[Codex](https://developers.openai.com/codex/skills/). Marketplace upload rules should be rechecked with
[Agensi sell](https://www.agensi.io/sell) before submission.
