import { Injectable } from "@nestjs/common";
import { Prisma } from "@prisma/client";
import { PrismaService } from "../prisma/prisma.service";
import { PARENT_CHAIN } from "../category/category-chain";

const WITH_CATEGORY_CHAIN = { category: { include: PARENT_CHAIN } } satisfies Prisma.contentInclude;

@Injectable()
export class ContentRepository {
    constructor(private readonly prisma: PrismaService) {}

    findPage(skip: number, take: number) {
        return this.prisma.content.findMany({
            skip,
            take,
            orderBy: { id: "asc" },
            include: WITH_CATEGORY_CHAIN,
        });
    }

    findById(id: number) {
        return this.prisma.content.findUnique({ where: { id }, include: WITH_CATEGORY_CHAIN });
    }

    /** Rewrites only the text; returns null when no row has this id. */
    async updateText(id: number, content: string) {
        try {
            return await this.prisma.content.update({ where: { id }, data: { content } });
        } catch (e) {
            if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === "P2025") return null;
            throw e;
        }
    }
}
