import { LogLevel } from "@nestjs/common";

const ORDER: LogLevel[] = ["fatal", "error", "warn", "log", "debug", "verbose"];

/** LOG_LEVEL=warn (default) enables fatal, error and warn; LOG_LEVEL=debug also logs SQL. */
export function logLevels(level: string | undefined): LogLevel[] {
    const name = (level ?? "warn").toLowerCase();
    const index = ORDER.indexOf((name === "info" ? "log" : name) as LogLevel);
    return ORDER.slice(0, (index < 0 ? ORDER.indexOf("warn") : index) + 1);
}
