import { content as ContentRow } from "@prisma/client";
import { CategoryWithParents } from "../../category/category-chain";
import { CategoryResponse } from "../../category/dto/category.response";

/** A content row without its category (the PUT response). */
export class ContentSummaryResponse {
    id: number;
    category_id: number | null;
    content: string;

    static from(row: ContentRow): ContentSummaryResponse {
        const dto = new ContentSummaryResponse();
        dto.id = row.id;
        dto.category_id = row.category_id;
        dto.content = row.content;
        return dto;
    }
}

/** A content row with its category and the category's full parent chain (list and item). */
export class ContentResponse {
    id: number;
    category_id: number | null;
    content: string;
    category: CategoryResponse | null;

    static from(row: ContentRow & { category: CategoryWithParents | null }): ContentResponse {
        const dto = new ContentResponse();
        dto.id = row.id;
        dto.category_id = row.category_id;
        dto.content = row.content;
        dto.category = row.category ? CategoryResponse.from(row.category) : null;
        return dto;
    }
}

export class PageMeta {
    constructor(
        readonly page: number,
        readonly pageSize: number,
    ) {}
}
