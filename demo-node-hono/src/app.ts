import { Hono } from "hono";
import { HTTPException } from "hono/http-exception";
import type { ContentfulStatusCode } from "hono/utils/http-status";
import type { Db } from "./db/client.js";
import type { Env } from "./env.js";
import { categories } from "./routes/categories.js";
import { contents } from "./routes/contents.js";

const REASONS: Record<number, string> = { 400: "Bad Request", 404: "Not Found", 500: "Internal Server Error" };

/** The whole HTTP app, built around one database handle. Shared by index.ts and the tests. */
export function createApp(db: Db) {
    const app = new Hono<Env>();
    app.use(async (c, next) => {
        c.set("db", db);
        await next();
    });

    app.route("/api/categories", categories);
    app.route("/api/contents", contents);

    // Every error is JSON {statusCode, message, error}; anything unexpected is a logged 500.
    app.notFound((c) => c.json({ statusCode: 404, message: `Cannot ${c.req.method} ${c.req.path}`, error: "Not Found" }, 404));
    app.onError((err, c) => {
        if (err instanceof HTTPException) {
            const status = err.status as ContentfulStatusCode;
            return c.json({ statusCode: status, message: err.message, error: REASONS[status] ?? "Error" }, status);
        }
        console.error(err);
        return c.json({ statusCode: 500, message: "Internal server error" }, 500);
    });
    return app;
}
