import { integer, sqliteTable, text } from "drizzle-orm/sqlite-core";

// Maps the existing tables; this demo never migrates the schema.
export const category = sqliteTable("category", {
    id: integer("id").primaryKey(),
    parentId: integer("parent_id"),
    name: text("name").notNull(),
});

export const content = sqliteTable("content", {
    id: integer("id").primaryKey(),
    categoryId: integer("category_id"),
    content: text("content").notNull(),
});

export type CategoryRow = typeof category.$inferSelect;
export type ContentRow = typeof content.$inferSelect;
