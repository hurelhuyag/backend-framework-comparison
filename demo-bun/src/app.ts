import type { Serve } from "bun";
import type { Db } from "./db";

const REASONS: Record<number, string> = { 400: "Bad Request", 404: "Not Found", 500: "Internal Server Error" };
const INT4_MAX = 2147483647;

/** Every error is JSON {statusCode, message, error}. */
class HttpError extends Error {
    constructor(readonly status: number, message: string) {
        super(message);
    }
}

function errorResponse(status: number, message: string) {
    return Response.json({ statusCode: status, message, error: REASONS[status] ?? "Error" }, { status });
}

/** Decimal integer (within JavaScript's safe range) or null; `fallback` when absent. */
function int(value: string | null | undefined, fallback?: number): number | null {
    if (value === null || value === undefined) return fallback ?? null;
    const n = /^-?\d+$/.test(value) ? Number(value) : NaN;
    return Number.isSafeInteger(n) ? n : null;
}

function intParam(value: string | null, name: string, fallback: number, min: number, max: number): number {
    const n = int(value, fallback);
    if (n === null || n < min || n > max) throw new HttpError(400, `${name} must be an integer from ${min} to ${max}`);
    return n;
}

function idParam(value: string): number {
    const id = int(value);
    if (id === null) throw new HttpError(400, "id must be an integer");
    return id;
}

/** Ids outside the integer column's range cannot exist; answering 404 keeps them out of the database. */
const inRange = (id: number) => Math.abs(id) <= INT4_MAX;

async function contentText(req: Request): Promise<string> {
    let body: unknown;
    try {
        body = await req.json();
    } catch {
        throw new HttpError(400, "Request body is not valid JSON");
    }
    const text = (body as { content?: unknown } | null)?.content;
    if (typeof text !== "string" || text.length === 0) throw new HttpError(400, "content must be a non-empty string");
    return text;
}

const notFound = (id: number) => new HttpError(404, `Content ${id} not found`);

/** Routes plus fallback and error handler, shared by index.ts and the tests. */
export function serverOptions(db: Db) {
    return {
        routes: {
            "/api/categories": {
                GET: async () => Response.json({ data: await db.categories() }),
            },
            "/api/contents": {
                GET: async (req) => {
                    const query = new URL(req.url).searchParams;
                    const page = intParam(query.get("page"), "page", 1, 1, 1_000_000_000);
                    const pageSize = intParam(query.get("pageSize"), "pageSize", 20, 1, 100);
                    const data = await db.contentPage(pageSize, (page - 1) * pageSize);
                    return Response.json({ meta: { page, pageSize }, data });
                },
            },
            "/api/contents/:id": {
                GET: async (req) => {
                    const id = idParam(req.params.id);
                    const row = inRange(id) ? await db.contentById(id) : null;
                    if (!row) throw notFound(id);
                    return Response.json({ data: row });
                },
                // Rewrites only the text, so the row count never changes and reads stay comparable.
                PUT: async (req) => {
                    const id = idParam(req.params.id);
                    const text = await contentText(req);
                    const row = inRange(id) ? await db.updateContent(id, text) : null;
                    if (!row) throw notFound(id);
                    return Response.json({ data: row });
                },
            },
        },
        fetch: (req) => errorResponse(404, `Cannot ${req.method} ${new URL(req.url).pathname}`),
        error: (err) => {
            if (err instanceof HttpError) return errorResponse(err.status, err.message);
            console.error(err);
            return Response.json({ statusCode: 500, message: "Internal server error" }, { status: 500 });
        },
    } satisfies Serve.Options<undefined, "/api/categories" | "/api/contents" | "/api/contents/:id">;
}
