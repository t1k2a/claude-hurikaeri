---
name: standup
description: Use when the user explicitly invokes the legacy /standup command. Compatibility entry for Dev Rewind; install dev-rewind alongside standup.
---

# Dev Rewind — legacy /standup entry

Read [Dev Rewind](../dev-rewind/SKILL.md) and follow its workflow, passing the user's
original arguments unchanged. /standup morning is equivalent to /dev-rewind morning.
Use Dev Rewind for new installations. This alias needs the sibling dev-rewind folder.

If that file is missing, explain that both folders must be installed in the same skills
directory and point to the repository README. Do not guess the workflow or run legacy
helpers. Do not install anything automatically.

Existing .standup-history records and notification variable names remain unchanged.
