export type SchedulePreset = "daily" | "weekly" | "custom";

export interface ScheduleConfig {
  preset: SchedulePreset;
  /** cron expression for "custom" preset */
  cronExpression?: string;
}

/**
 * Convert a schedule preset to a cron expression string.
 * - daily  → runs at 09:00 every day
 * - weekly → runs at 09:00 every Monday
 * - custom → uses the caller-supplied cronExpression
 */
export function getCronExpression(config: ScheduleConfig): string {
  switch (config.preset) {
    case "daily":
      return "0 9 * * *";
    case "weekly":
      return "0 9 * * 1";
    case "custom":
      if (!config.cronExpression) {
        throw new Error(
          'cronExpression must be provided when preset is "custom"'
        );
      }
      return config.cronExpression;
    default:
      throw new Error(`Unknown schedule preset: ${config.preset}`);
  }
}

/**
 * Generate a systemd timer unit file content for the given schedule.
 *
 * @param serviceName  Name of the associated systemd service (without .service suffix)
 * @param config       Schedule configuration
 * @returns            Content of the .timer unit file as a string
 */
export function generateSystemdTimer(
  serviceName: string,
  config: ScheduleConfig
): string {
  // systemd OnCalendar uses a slightly different format from cron.
  // Map common presets directly; for custom, use the cron expression as-is
  // (callers may need to adjust for their systemd version).
  let onCalendar: string;
  switch (config.preset) {
    case "daily":
      onCalendar = "*-*-* 09:00:00";
      break;
    case "weekly":
      onCalendar = "Mon *-*-* 09:00:00";
      break;
    case "custom":
      onCalendar = config.cronExpression ?? "daily";
      break;
    default:
      onCalendar = "daily";
  }

  return `[Unit]
Description=Standup report scheduled delivery (${config.preset})
Requires=${serviceName}.service

[Timer]
OnCalendar=${onCalendar}
Persistent=true

[Install]
WantedBy=timers.target
`;
}

/**
 * Generate a crontab line that runs a given command on the configured schedule.
 *
 * @param command  Shell command to execute (e.g. "claude-hurikaeri-mcp ...")
 * @param config   Schedule configuration
 * @returns        A crontab entry string
 */
export function generateCrontabEntry(
  command: string,
  config: ScheduleConfig
): string {
  const cron = getCronExpression(config);
  return `${cron} ${command}`;
}
