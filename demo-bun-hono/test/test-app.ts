import { createApp } from "../src/app";
import { openDb, type Db } from "../src/db/client";

/**
 * Builds the real app (same routes and error handling as index.ts) on the database in
 * DATABASE_URL. ../test.sh hands every run a fresh clone of demo_template (db/generate.sql).
 */
export function createTestApp(): { app: ReturnType<typeof createApp>; db: Db; close: () => Promise<void> } {
    const url = process.env.DATABASE_URL;
    if (!url) throw new Error("DATABASE_URL is not set (run ../test.sh bun-hono, or point it at a clone of demo_template)");
    const db = openDb(url);
    return { app: createApp(db), db, close: () => db.close() };
}
