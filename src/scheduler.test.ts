import { strict as assert } from "assert";
import { test } from "node:test";
import {
  getCronExpression,
  generateCrontabEntry,
  generateSystemdTimer,
} from "./scheduler.js";

test("getCronExpression returns daily cron for 'daily' preset", () => {
  const cron = getCronExpression({ preset: "daily" });
  assert.equal(cron, "0 9 * * *");
});

test("getCronExpression returns weekly cron for 'weekly' preset", () => {
  const cron = getCronExpression({ preset: "weekly" });
  assert.equal(cron, "0 9 * * 1");
});

test("getCronExpression returns custom cron expression when preset is 'custom'", () => {
  const cron = getCronExpression({
    preset: "custom",
    cronExpression: "30 8 * * 1-5",
  });
  assert.equal(cron, "30 8 * * 1-5");
});

test("getCronExpression throws when 'custom' preset has no cronExpression", () => {
  assert.throws(() => getCronExpression({ preset: "custom" }), /cronExpression/);
});

test("generateCrontabEntry prefixes cron to command", () => {
  const entry = generateCrontabEntry("my-command --flag", { preset: "daily" });
  assert.equal(entry, "0 9 * * * my-command --flag");
});

test("generateSystemdTimer returns valid unit file content for 'daily'", () => {
  const timer = generateSystemdTimer("my-service", { preset: "daily" });
  assert.ok(timer.includes("[Timer]"));
  assert.ok(timer.includes("OnCalendar=*-*-* 09:00:00"));
});

test("generateSystemdTimer returns valid unit file content for 'weekly'", () => {
  const timer = generateSystemdTimer("my-service", { preset: "weekly" });
  assert.ok(timer.includes("OnCalendar=Mon *-*-* 09:00:00"));
});
