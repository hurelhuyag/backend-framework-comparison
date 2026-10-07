import type { CategoryRow } from "../db/schema";
import type { ContentRow } from "../db/schema";

export type CategoryView = {
    id: number;
    parent_id: number | null;
    name: string;
    parent: CategoryView | null;
};

export type ContentView = {
    id: number;
    category_id: number | null;
    content: string;
    category: CategoryView | null;
};

// The data is at most 3 levels deep (10 roots, 30 at depth 2, 60 at depth 3), which is the
// same chain Hibernate's fetch joins and Prisma's nested include load in the other demos.
export function categoryChain(rows: (CategoryRow | null)[]): CategoryView | null {
    let view: CategoryView | null = null;

    for (let i = rows.length - 1; i >= 0; i -= 1) {
        const row = rows[i];

        if (row !== null && row !== undefined) {
            view = { id: row.id, parent_id: row.parentId, name: row.name, parent: view };
        }
    }

    return view;
}

export function contentView(row: ContentRow, chain: (CategoryRow | null)[]): ContentView {
    return {
        id: row.id,
        category_id: row.categoryId,
        content: row.content,
        category: categoryChain(chain),
    };
}
