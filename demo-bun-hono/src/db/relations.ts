import { defineRelations } from "drizzle-orm";
import * as schema from "./schema";

export const relations = defineRelations(schema, (r) => ({
    category: {
        parent: r.one.category({ from: r.category.parent_id, to: r.category.id }),
    },
    content: {
        category: r.one.category({ from: r.content.category_id, to: r.category.id }),
    },
}));
