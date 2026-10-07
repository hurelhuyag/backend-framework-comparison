import { integer, pgTable, text, unique, type AnyPgColumn } from "drizzle-orm/pg-core";

// Mirrors db/generate.sql. The tables already exist in the database; nothing is migrated.
export const category = pgTable(
    "category",
    {
        id: integer("id").primaryKey(),
        parent_id: integer("parent_id").references((): AnyPgColumn => category.id),
        name: text("name").notNull(),
    },
    (t) => [unique().on(t.parent_id, t.name)],
);

export const content = pgTable("content", {
    id: integer("id").primaryKey(),
    category_id: integer("category_id").references(() => category.id),
    content: text("content").notNull(),
});

export type CategoryRow = typeof category.$inferSelect;
export type ContentRow = typeof content.$inferSelect;
