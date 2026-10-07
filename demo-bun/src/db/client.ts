import { Database } from "bun:sqlite";
import { drizzle } from "drizzle-orm/bun-sqlite";
import * as schema from "./schema";

const path = process.env.DEMO_DB ?? "demo.sqlite";

const sqlite = new Database(path);

// Writes here are single autocommitted statements, so they only ever wait to ACQUIRE the
// write lock - never to upgrade one - which is exactly the case busy_timeout covers.
sqlite.exec("PRAGMA busy_timeout = 5000");

export const db = drizzle(sqlite, { schema });
