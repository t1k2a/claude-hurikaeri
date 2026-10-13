# Standup distribution preparation

Goal: prepare the existing standup skill for a first marketplace listing, without adding integrations or publishing.

Design: keep `standup` as the stable invocation and folder name while the product name is undecided. Keep the Git-based meeting workflow in SKILL.md; move optional output/history operations into one reference. Package only reviewed text files and the existing MIT license. Do not bundle the separate npm MCP implementation or legacy shell helpers.

1. Record baseline scenarios: PowerShell without gh, unsafe report characters, history-only requests.
2. Rewrite skills/standup/SKILL.md and default-template.md; add references/optional-operations.md, README.md and synthetic examples.
3. Add a fixed-allowlist ZIP builder and isolation tests proving private/untracked files are excluded.
4. Validate Git commands in a synthetic repository; rerun behavioral scenarios; syntax-check existing shell files.
5. Record package identity, compatibility limits, license findings, naming migration and listing draft in docs/distribution.md.
6. Commit a review branch and open a normal PR. No merge, npm release, marketplace upload, account registration or license change.

Existing checkout: contains user changes and is read-only for this task. The isolated checkout uses public main 39428d1c8f90d64f7507ef127e1e06ae36aa5d69. Windows sparse checkout excludes .github because upstream has a trailing-space filename; the upstream file is preserved in Git.

Naming update: owner selected Dev Rewind. The canonical Skill is skills/dev-rewind; skills/standup is a compatibility alias requiring both folders. Repo/npm identifiers remain unchanged.
