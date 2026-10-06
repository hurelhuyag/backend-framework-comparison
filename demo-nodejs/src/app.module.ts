import { Module } from "@nestjs/common";
import { PrismaModule } from "./prisma/prisma.module";
import { CategoryModule } from "./category/category.module";
import { ContentModule } from "./content/content.module";

@Module({
    imports: [PrismaModule, CategoryModule, ContentModule],
})
export class AppModule {}
