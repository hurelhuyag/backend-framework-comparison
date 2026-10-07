import { Hono } from "hono";
import { PARENT_CHAIN, toCategoryResponse } from "../db/category-chain.js";
import type { Env } from "../env.js";

export const categories = new Hono<Env>().get("/", async (c) => {
    const rows = await c.var.db.query.category.findMany({ orderBy: { id: "asc" }, with: PARENT_CHAIN });
    return c.json({ data: rows.map(toCategoryResponse) });
});
