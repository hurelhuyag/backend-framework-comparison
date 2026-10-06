import { Injectable } from "@nestjs/common";
import { CategoryRepository } from "./category.repository";
import { CategoryResponse } from "./dto/category.response";

@Injectable()
export class CategoryService {
    constructor(private readonly categories: CategoryRepository) {}

    async findAll(): Promise<CategoryResponse[]> {
        const rows = await this.categories.findAllWithParents();
        return rows.map((row) => CategoryResponse.from(row));
    }
}
