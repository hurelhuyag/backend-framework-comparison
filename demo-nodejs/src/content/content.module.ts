import { Module } from "@nestjs/common";
import { ContentController } from "./content.controller";
import { ContentRepository } from "./content.repository";
import { ContentService } from "./content.service";

@Module({
    controllers: [ContentController],
    providers: [ContentService, ContentRepository],
})
export class ContentModule {}
