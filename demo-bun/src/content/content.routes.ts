import { zValidator } from "@hono/zod-validator";
import { Hono } from "hono";
import { resolvePage } from "../common/pagination";
import { getById, getPage, updateText } from "./content.service";
import { updateContentRequest } from "./dto/update-content.request";

export const contentRoutes = new Hono();

contentRoutes.get("/contents", async (c) => {
    const { page, size, offset } = resolvePage(c.req.query());

    return c.json({
        meta: { page, pageSize: size },
        data: await getPage(offset, size),
    });
});

contentRoutes.get("/contents/:id{[0-9]+}", async (c) => {
    const found = await getById(Number(c.req.param("id")));

    return found === null
        ? c.json({ error: "content not found" }, 404)
        : c.json({ data: found });
});

contentRoutes.put(
    "/contents/:id{[0-9]+}",
    zValidator("json", updateContentRequest, (result, c) => {
        if (!result.success) {
            return c.json({ error: "validation_failed", details: result.error.issues }, 400);
        }
    }),
    async (c) => {
        const updated = await updateText(Number(c.req.param("id")), c.req.valid("json").content);

        return updated === null
            ? c.json({ error: "content not found" }, 404)
            : c.json({ data: updated });
    },
);
