import { Injectable } from "@nestjs/common";
import { PrismaService } from "../prisma/prisma.service";
import { PARENT_CHAIN } from "./category-chain";

@Injectable()
export class CategoryRepository {
    constructor(private readonly prisma: PrismaService) {}

    findAllWithParents() {
        return this.prisma.category.findMany({ orderBy: { id: "asc" }, include: PARENT_CHAIN });
    }
}
