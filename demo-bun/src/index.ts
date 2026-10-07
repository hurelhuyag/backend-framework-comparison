import { readFileSync } from "node:fs";
import { Hono } from "hono";
import { categoryRoutes } from "./category/category.routes";
import { contentRoutes } from "./content/content.routes";

const app = new Hono();

// Mounted at both /... and /api/... so either benchmark URL shape works.
for (const prefix of ["/", "/api"]) {
    app.route(prefix, contentRoutes);
    app.route(prefix, categoryRoutes);
}

app.onError((err, c) => {
    console.error(err);

    return c.json({ error: "internal_error" }, 500);
});

// Bun.serve is single-threaded, so one process uses one core no matter the concurrency. The
// JVM and .NET read the cgroup quota and size their thread pools from it; do the same here
// and fork that many listeners sharing the port via SO_REUSEPORT, the way gunicorn and
// php-fpm run multiple workers. navigator.hardwareConcurrency would report the HOST's cores
// and oversubscribe a cpu-limited container.
function cpuQuota(): number {
    try {
        const [quota, period] = readFileSync("/sys/fs/cgroup/cpu.max", "utf8").trim().split(/\s+/);

        if (quota !== "max") {
            return Math.max(1, Math.round(Number(quota) / Number(period)));
        }
    } catch {
        // not cgroup v2, or not containerised
    }

    return navigator.hardwareConcurrency ?? 1;
}

const port = Number(process.env.PORT ?? 8084);
const workers = Number(process.env.WORKERS ?? cpuQuota());

if (workers > 1 && process.env.BUN_WORKER === undefined) {
    for (let i = 0; i < workers; i += 1) {
        // Bun.argv reproduces this process's own command line, so this works for
        // `bun run src/index.ts`, `bun dist/server.js` and a --compile'd binary alike.
        Bun.spawn([...Bun.argv], {
            env: { ...process.env, BUN_WORKER: String(i) },
            stdout: "inherit",
            stderr: "inherit",
        });
    }

    console.log(`listening on :${port} with ${workers} workers`);
    await new Promise(() => {});
} else {
    Bun.serve({ port, reusePort: true, fetch: app.fetch });
}
