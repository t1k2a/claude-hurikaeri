# Skills Marketplace Registration Guide

このドキュメントは claude-hurikaeri スキルを Claude Code スキルマーケットプレイスに登録する手順を説明します。
ただし、現時点では**ローカル利用に留める方針**です（2026-04-25 経営判断）。

> **Note:** External publication is currently on hold per management policy. This document serves as preparation for future marketplace registration when the policy changes.

## Supported Marketplaces

| Marketplace | URL | Revenue Share | Status |
|-------------|-----|---------------|--------|
| SkillHQ | https://skillhq.dev/ | 85% to seller | Planned (on hold) |
| skillsmp.com | https://skillsmp.com | TBD | Planned (on hold) |
| claudemarketplaces.com | https://claudemarketplaces.com/ | TBD | Planned (on hold) |

## Registration Steps (SkillHQ)

1. **Create an account** at https://skillhq.dev/
2. **Prepare the skill package**
   - Ensure `SKILL.md` has a valid frontmatter with `name`, `description`, and `argument-hint`
   - Add English descriptions alongside Japanese text for international reach
   - Verify the skill works end-to-end in a clean Claude Code environment
3. **Submit the listing**
   - Upload `SKILL.md` and supporting scripts
   - Set pricing: Free (OSS) or paid tier
   - Add tags: `standup`, `webhook`, `team`, `automation`, `japanese`
4. **Review process**
   - Marketplace reviews for quality and safety (typically 2-5 business days)
5. **Publish**
   - Once approved, the skill is listed and users can install it

## Skill Quality Checklist (pre-submission)

- [ ] `SKILL.md` frontmatter is complete (`name`, `description`)
- [ ] Script passes `bash -n` syntax check
- [ ] README has a Quick Start section
- [ ] Environment variable requirements are documented
- [ ] Error messages are clear and actionable
- [ ] Tested on macOS and Linux (WSL)
- [ ] All PRs (#39, #40, #41, #45, #47, #51) merged and main is stable
- [ ] CHANGELOG or release notes are up to date
- [ ] `setup.sh` onboarding script is verified end-to-end

## Pricing Strategy

Following the freemium model described in [PRICING.md](../PRICING.md):

- **Free listing**: Core standup skill (single user)
- **Pro listing** (future): Team features, multi-webhook, dashboard (requires support contract)

## Pre-publication Workflow (Internal)

When management policy changes to allow publication, run the following steps:

```bash
# 1. Verify all scripts pass syntax check
for f in skills/standup/*.sh; do bash -n "$f" && echo "OK: $f"; done

# 2. Run onboarding setup in a clean environment
bash skills/standup/setup.sh --dry-run

# 3. Test Webhook notification
WEBHOOK_URL="<your-test-webhook>" bash skills/standup/cron-standup.sh

# 4. Generate dashboard to confirm HTML output
bash skills/standup/dashboard.sh

# 5. Final review of SKILL.md for marketplace compliance
head -20 skills/standup/SKILL.md
```

## Notes

- All marketplace registrations are subject to the MIT License terms
- Revenue from marketplace sales (if any) funds ongoing development and support
- For questions, open a GitHub Issue with label `marketplace`
- Current open PRs must be merged before submission to ensure listing reflects latest features
