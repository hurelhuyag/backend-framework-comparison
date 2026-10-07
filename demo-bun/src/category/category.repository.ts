import { asc, eq } from "drizzle-orm";
import { alias } from "drizzle-orm/sqlite-core";
import { db } from "../db/client";
import { category } from "../db/schema";

const par = alias(category, "par");
const gpar = alias(category, "gpar");

export function listCategories() {
    return db
        .select({ category: category, parent: par, grandparent: gpar })
        .from(category)
        .leftJoin(par, eq(category.parentId, par.id))
        .leftJoin(gpar, eq(par.parentId, gpar.id))
        .orderBy(asc(category.id));
}
