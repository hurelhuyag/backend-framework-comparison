import cluster from "node:cluster";
import { serve } from "@hono/node-server";
import { createApp } from "./app.js";
import { openDb } from "./db/client.js";

// One JavaScript thread per process, so the primary forks WORKERS processes (default 4, one per
// core) with node:cluster and they share the port. The primary only forks and supervises; each
// worker gets an equal share of the DB_POOL_SIZE connection budget.
const workers = Math.max(1, Number(process.env.WORKERS ?? 4));
const port = Number(process.env.PORT ?? 3002);
const debug = process.env.LOG_LEVEL?.toLowerCase() === "debug";

if (cluster.isPrimary) {
    let stopping = false;
    for (let i = 0; i < workers; i++) cluster.fork();
    // A worker that dies takes the whole server down, so the container restarts cleanly.
    cluster.on("exit", (worker, code) => {
        if (stopping) return;
        console.error(`worker ${worker.process.pid} exited with code ${code}`);
        stopping = true;
        for (const w of Object.values(cluster.workers ?? {})) w?.kill("SIGTERM");
        process.exitCode = 1;
    });
    for (const signal of ["SIGINT", "SIGTERM"] as const) {
        process.on(signal, () => {
            stopping = true;
            for (const w of Object.values(cluster.workers ?? {})) w?.kill("SIGTERM");
        });
    }
    if (debug) console.debug(`Listening on port ${port} with ${workers} workers`);
} else {
    const poolSize = Math.max(1, Math.floor(Number(process.env.DB_POOL_SIZE ?? 32) / workers));
    const db = openDb(process.env.DATABASE_URL ?? "postgres://bench:bench@127.0.0.1:5432/demo", poolSize);
    const server = serve({ fetch: createApp(db).fetch, port });

    for (const signal of ["SIGINT", "SIGTERM"] as const) {
        process.on(signal, () => {
            server.close(async () => {
                await db.close();
                process.exit(0);
            });
        });
    }
}
