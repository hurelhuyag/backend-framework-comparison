import { Prisma } from "@prisma/client";

/**
 * Prisma include that loads a category's full parent chain. The data has at most 3 levels, so
 * 3 hops always end at a root's `parent: null`. Prisma batches each level into one
 * `WHERE id IN (...)` query and skips a level when every parent_id in it is null.
 */
export const PARENT_CHAIN = {
    parent: { include: { parent: { include: { parent: true } } } },
} satisfies Prisma.categoryInclude;

/** A category row with (part of) its parent chain loaded. */
export type CategoryWithParents = {
    id: number;
    parent_id: number | null;
    name: string;
    parent?: CategoryWithParents | null;
};
