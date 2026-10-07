import type { CategoryRow } from "./schema.js";

/**
 * Relational-query `with` that loads a category's full parent chain. The data has at most 3
 * levels, so 3 hops always end at a root's `parent: null`. Drizzle turns the whole chain into
 * LEFT JOIN LATERAL subqueries of the one SELECT.
 */
export const PARENT_CHAIN = {
    parent: { with: { parent: { with: { parent: true } } } },
} as const;

/** A category row with (part of) its parent chain loaded; the last hop has no `parent` key. */
export type CategoryWithParents = CategoryRow & { parent?: CategoryWithParents | null };

export type CategoryResponse = {
    id: number;
    parent_id: number | null;
    name: string;
    parent: CategoryResponse | null;
};

export function toCategoryResponse(row: CategoryWithParents): CategoryResponse {
    return {
        id: row.id,
        parent_id: row.parent_id,
        name: row.name,
        parent: row.parent ? toCategoryResponse(row.parent) : null,
    };
}
