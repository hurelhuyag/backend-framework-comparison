import { Hono } from "hono";
import { getAll } from "./category.service";

export const categoryRoutes = new Hono();

categoryRoutes.get("/categories", async (c) => c.json({ data: await getAll() }));
