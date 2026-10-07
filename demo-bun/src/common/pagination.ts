export const DEFAULT_SIZE = 20;
export const MAX_SIZE = 100;

// Accepts size, page_size and pageSize so one benchmark URL shape works across demos.
export function resolvePage(query: Record<string, string | undefined>) {
    const page = Math.max(1, Number(query.page ?? 1) || 1);
    const requested = Number(query.size ?? query.page_size ?? query.pageSize ?? DEFAULT_SIZE);
    const size = Number.isFinite(requested) && requested > 0
        ? Math.min(requested, MAX_SIZE)
        : DEFAULT_SIZE;

    return { page, size, offset: (page - 1) * size };
}
