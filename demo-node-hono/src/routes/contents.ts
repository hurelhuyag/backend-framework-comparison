import { Hono } from "hono";
import { HTTPException } from "hono/http-exception";
import { eq } from "drizzle-orm";
import { z } from "zod";
import { PARENT_CHAIN, toCategoryResponse, type CategoryWithParents } from "../db/category-chain.js";
import { content, type ContentRow } from "../db/schema.js";
import type { Env } from "../env.js";
import { validate } from "../validate.js";

const WITH_CATEGORY_CHAIN = { category: { with: PARENT_CHAIN } } as const;

const listQuery = z.object({
    page: z.coerce.number().int().min(1).default(1),
    pageSize: z.coerce.number().int().min(1).max(100).default(20),
});
const idParam = z.object({ id: z.coerce.number().int() });
const updateBody = z.object({ content: z.string().min(1) });

/** A content row without its category (the PUT response). */
function toSummary(row: ContentRow) {
    return { id: row.id, category_id: row.category_id, content: row.content };
}

/** A content row with its category and the category's full parent chain (list and item). */
function toResponse(row: ContentRow & { category: CategoryWithParents | null }) {
    return { ...toSummary(row), category: row.category ? toCategoryResponse(row.category) : null };
}

function notFound(id: number): never {
    throw new HTTPException(404, { message: `Content ${id} not found` });
}

export const contents = new Hono<Env>()
    .get("/", validate("query", listQuery), async (c) => {
        const { page, pageSize } = c.req.valid("query");
        const rows = await c.var.db.query.content.findMany({
            offset: (page - 1) * pageSize,
            limit: pageSize,
            orderBy: { id: "asc" },
            with: WITH_CATEGORY_CHAIN,
        });
        return c.json({ meta: { page, pageSize }, data: rows.map(toResponse) });
    })
    .get("/:id", validate("param", idParam), async (c) => {
        const { id } = c.req.valid("param");
        const row = await c.var.db.query.content.findFirst({ where: { id }, with: WITH_CATEGORY_CHAIN });
        if (!row) notFound(id);
        return c.json({ data: toResponse(row) });
    })
    // Rewrites only the text, so the row count never changes and reads stay comparable.
    .put("/:id", validate("param", idParam), validate("json", updateBody), async (c) => {
        const { id } = c.req.valid("param");
        const [row] = await c.var.db
            .update(content)
            .set({ content: c.req.valid("json").content })
            .where(eq(content.id, id))
            .returning();
        if (!row) notFound(id);
        return c.json({ data: toSummary(row) });
    });
