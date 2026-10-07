import { SQL } from "bun";

export type Db = ReturnType<typeof openDb>;

export type CategoryJson = { id: number; parent_id: number | null; name: string; parent: CategoryJson | null };
export type ContentSummaryJson = { id: number; category_id: number | null; content: string };
export type ContentJson = ContentSummaryJson & { category: CategoryJson | null };

// The data has at most 3 category levels, so a category plus two joined parents is always the
// whole chain. c1 is the row's own category (for content) or the category itself.
const CHAIN_COLUMNS = `
    c1.id as c1_id, c1.parent_id as c1_parent_id, c1.name as c1_name,
    c2.id as c2_id, c2.parent_id as c2_parent_id, c2.name as c2_name,
    c3.id as c3_id, c3.parent_id as c3_parent_id, c3.name as c3_name`;
const CHAIN_JOINS = `
    left join category c2 on c2.id = c1.parent_id
    left join category c3 on c3.id = c2.parent_id`;

type ChainRow = Record<`c${1 | 2 | 3}_${"id" | "parent_id" | "name"}`, any>;

/** Nests the joined c1 -> c2 -> c3 columns into category -> parent -> parent. */
function chain(row: ChainRow, level = 1): CategoryJson | null {
    const id = row[`c${level as 1 | 2 | 3}_id`];
    if (id === null || level > 3) return null;
    return {
        id,
        parent_id: row[`c${level as 1 | 2 | 3}_parent_id`],
        name: row[`c${level as 1 | 2 | 3}_name`],
        parent: level < 3 ? chain(row, level + 1) : null,
    };
}

function toContent(row: ContentSummaryJson & ChainRow): ContentJson {
    return { id: row.id, category_id: row.category_id, content: row.content, category: chain(row) };
}

/** Bun's built-in PostgreSQL client and the four queries the API needs, as plain SQL. */
export function openDb(url: string, poolSize = Number(process.env.DB_POOL_SIZE ?? 32)) {
    const sql = new SQL(url, { max: poolSize });

    return {
        sql,

        async contentPage(limit: number, offset: number): Promise<ContentJson[]> {
            const rows = await sql.unsafe(
                `select ct.id, ct.category_id, ct.content, ${CHAIN_COLUMNS}
                 from content ct left join category c1 on c1.id = ct.category_id ${CHAIN_JOINS}
                 order by ct.id limit $1 offset $2`,
                [limit, offset],
            );
            return rows.map(toContent);
        },

        async contentById(id: number): Promise<ContentJson | null> {
            const [row] = await sql.unsafe(
                `select ct.id, ct.category_id, ct.content, ${CHAIN_COLUMNS}
                 from content ct left join category c1 on c1.id = ct.category_id ${CHAIN_JOINS}
                 where ct.id = $1`,
                [id],
            );
            return row ? toContent(row) : null;
        },

        /** Rewrites only the text; null when no row has this id. */
        async updateContent(id: number, text: string): Promise<ContentSummaryJson | null> {
            const [row] = await sql`
                update content set content = ${text} where id = ${id}
                returning id, category_id, content`;
            return row ?? null;
        },

        async categories(): Promise<CategoryJson[]> {
            const rows = await sql.unsafe(
                `select ${CHAIN_COLUMNS} from category c1 ${CHAIN_JOINS} order by c1.id`,
            );
            return rows.map((row: ChainRow) => chain(row)!);
        },

        close: () => sql.close(),
    };
}
