import { Controller, Get } from "@nestjs/common";
import { CategoryService } from "./category.service";
import { CategoryResponse } from "./dto/category.response";

@Controller("categories")
export class CategoryController {
    constructor(private readonly categoryService: CategoryService) {}

    @Get()
    async findAll(): Promise<{ data: CategoryResponse[] }> {
        return { data: await this.categoryService.findAll() };
    }
}
