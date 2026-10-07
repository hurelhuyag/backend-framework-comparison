import type { Db } from "./db/client.js";

/** Hono context variables: every handler reads the database from `c.var.db`. */
export type Env = { Variables: { db: Db } };
