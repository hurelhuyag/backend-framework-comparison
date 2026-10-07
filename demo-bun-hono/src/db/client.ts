import { SQL } from "bun";
import { drizzle } from "drizzle-orm/bun-sql";
import { relations } from "./relations";

export type Db = ReturnType<typeof openDb>;

/** Bun's built-in PostgreSQL client (Bun.SQL), a pool of at most `poolSize` connections. */
export function openDb(url: string, poolSize = Number(process.env.DB_POOL_SIZE ?? 32)) {
    const client = new SQL(url, { max: poolSize });
    // LOG_LEVEL=debug logs every SQL statement; otherwise the logger is off and costs nothing.
    const logger = process.env.LOG_LEVEL?.toLowerCase() === "debug";
    return Object.assign(drizzle({ client, relations, logger }), { close: () => client.close() });
}
