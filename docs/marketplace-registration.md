# Skills Marketplace Registration Guide

This document describes how to register claude-hurikaeri skills on Claude Code skill marketplaces.

## Supported Marketplaces

| Marketplace | URL | Revenue Share | Status |
|-------------|-----|---------------|--------|
| SkillHQ | https://skillhq.dev/ | 85% to seller | Planned |
| skillsmp.com | https://skillsmp.com | TBD | Planned |
| claudemarketplaces.com | https://claudemarketplaces.com/ | TBD | Planned |

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

## Pricing Strategy

Following the freemium model described in [PRICING.md](../PRICING.md):

- **Free listing**: Core standup skill (single user)
- **Pro listing** (future): Team features, multi-webhook, dashboard (requires support contract)

## Notes

- All marketplace registrations are subject to the MIT License terms
- Revenue from marketplace sales (if any) funds ongoing development and support
- For questions, open a GitHub Issue with label `marketplace`
