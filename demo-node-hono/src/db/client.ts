import { drizzle } from "drizzle-orm/node-postgres";
import pg from "pg";
import { relations } from "./relations.js";

export type Db = ReturnType<typeof openDb>;

/** node-postgres pool of at most `poolSize` connections. */
export function openDb(url: string, poolSize = Number(process.env.DB_POOL_SIZE ?? 32)) {
    const pool = new pg.Pool({ connectionString: url, max: poolSize });
    // LOG_LEVEL=debug logs every SQL statement; otherwise the logger is off and costs nothing.
    const logger = process.env.LOG_LEVEL?.toLowerCase() === "debug";
    return Object.assign(drizzle({ client: pool, relations, logger }), { close: () => pool.end() });
}
