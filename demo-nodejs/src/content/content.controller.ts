import { Body, Controller, Get, Param, ParseIntPipe, Put, Query } from "@nestjs/common";
import { ContentService } from "./content.service";
import { ContentResponse, ContentSummaryResponse, PageMeta } from "./dto/content.response";
import { ListContentsQuery } from "./dto/list-contents.query";
import { UpdateContentRequest } from "./dto/update-content.request";

@Controller("contents")
export class ContentController {
    constructor(private readonly contentService: ContentService) {}

    @Get()
    async list(@Query() query: ListContentsQuery): Promise<{ meta: PageMeta; data: ContentResponse[] }> {
        const data = await this.contentService.findPage(query.page, query.pageSize);
        return { meta: new PageMeta(query.page, query.pageSize), data };
    }

    @Get(":id")
    async get(@Param("id", ParseIntPipe) id: number): Promise<{ data: ContentResponse }> {
        return { data: await this.contentService.findById(id) };
    }

    @Put(":id")
    async update(
        @Param("id", ParseIntPipe) id: number,
        @Body() body: UpdateContentRequest,
    ): Promise<{ data: ContentSummaryResponse }> {
        return { data: await this.contentService.updateText(id, body.content) };
    }
}
