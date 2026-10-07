import { serverOptions } from "./app";
import { openDb } from "./db";

// One JavaScript thread per process, so WORKERS processes (default 4, one per core) share the
// port through SO_REUSEPORT and the kernel spreads connections across them. The primary only
// spawns and supervises; each worker gets an equal share of the DB_POOL_SIZE connection budget.
const workers = Math.max(1, Number(process.env.WORKERS ?? 4));
const port = Number(process.env.PORT ?? 3003);
const debug = process.env.LOG_LEVEL?.toLowerCase() === "debug";

if (process.env.BUN_WORKER === undefined) {
    let stopping = false;
    const children = Array.from({ length: workers }, (_, i) =>
        Bun.spawn([process.execPath, ...process.argv.slice(1)], {
            env: { ...process.env, BUN_WORKER: String(i) },
            stdio: ["inherit", "inherit", "inherit"],
            // A worker that dies takes the whole server down, so the container restarts cleanly.
            onExit: (_proc, code) => {
                if (!stopping) {
                    console.error(`worker ${i} exited with code ${code}`);
                    stop(1);
                }
            },
        }),
    );
    const stop = async (code: number) => {
        stopping = true;
        for (const child of children) child.kill("SIGTERM");
        await Promise.all(children.map((child) => child.exited));
        process.exit(code);
    };
    process.on("SIGINT", () => stop(0));
    process.on("SIGTERM", () => stop(0));
    if (debug) console.debug(`Listening on port ${port} with ${workers} workers`);
} else {
    const poolSize = Math.max(1, Math.floor(Number(process.env.DB_POOL_SIZE ?? 32) / workers));
    const db = openDb(process.env.DATABASE_URL ?? "postgres://bench:bench@127.0.0.1:5432/demo", poolSize);
    const server = Bun.serve({ port, reusePort: true, ...serverOptions(db) });

    for (const signal of ["SIGINT", "SIGTERM"] as const) {
        process.on(signal, async () => {
            await server.stop();
            await db.close();
            process.exit(0);
        });
    }
}
