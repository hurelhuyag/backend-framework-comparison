import { asc, eq } from "drizzle-orm";
import { alias } from "drizzle-orm/sqlite-core";
import { db } from "../db/client";
import { category, content } from "../db/schema";

// Three aliased LEFT JOINs pull content -> category -> parent -> grandparent in ONE statement,
// the same chain Hibernate's fetch joins and Prisma's nested include load. The data is at most
// 3 levels deep, so this always terminates at a root. No COUNT(*) is issued.
const cat = alias(category, "cat");
const par = alias(category, "par");
const gpar = alias(category, "gpar");

const columns = {
    content: content,
    category: cat,
    parent: par,
    grandparent: gpar,
};

function joined<T extends { from: unknown }>(query: any) {
    return query
        .leftJoin(cat, eq(content.categoryId, cat.id))
        .leftJoin(par, eq(cat.parentId, par.id))
        .leftJoin(gpar, eq(par.parentId, gpar.id));
}

export function listContents(offset: number, limit: number) {
    return joined(db.select(columns).from(content))
        .orderBy(asc(content.id))
        .limit(limit)
        .offset(offset);
}

export function findContent(id: number) {
    return joined(db.select(columns).from(content))
        .where(eq(content.id, id))
        .limit(1);
}

// A single UPDATE, so the statement takes the write lock directly rather than upgrading a
// read lock - the failure mode that bites a read-modify-write inside one transaction.
export function updateContentText(id: number, text: string) {
    return db
        .update(content)
        .set({ content: text })
        .where(eq(content.id, id))
        .returning({ id: content.id });
}
