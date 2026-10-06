import { CategoryWithParents } from "../category-chain";

export class CategoryResponse {
    id: number;
    parent_id: number | null;
    name: string;
    parent: CategoryResponse | null;

    static from(row: CategoryWithParents): CategoryResponse {
        const dto = new CategoryResponse();
        dto.id = row.id;
        dto.parent_id = row.parent_id;
        dto.name = row.name;
        dto.parent = row.parent ? CategoryResponse.from(row.parent) : null;
        return dto;
    }
}
