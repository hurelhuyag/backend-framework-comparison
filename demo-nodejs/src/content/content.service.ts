import { Injectable, NotFoundException } from "@nestjs/common";
import { ContentRepository } from "./content.repository";
import { ContentResponse, ContentSummaryResponse } from "./dto/content.response";

@Injectable()
export class ContentService {
    constructor(private readonly contents: ContentRepository) {}

    async findPage(page: number, pageSize: number): Promise<ContentResponse[]> {
        const rows = await this.contents.findPage((page - 1) * pageSize, pageSize);
        return rows.map((row) => ContentResponse.from(row));
    }

    async findById(id: number): Promise<ContentResponse> {
        const row = await this.contents.findById(id);
        if (!row) throw new NotFoundException(`Content ${id} not found`);
        return ContentResponse.from(row);
    }

    // Rewrites only the text, so the row count never changes and reads stay comparable.
    async updateText(id: number, content: string): Promise<ContentSummaryResponse> {
        const row = await this.contents.updateText(id, content);
        if (!row) throw new NotFoundException(`Content ${id} not found`);
        return ContentSummaryResponse.from(row);
    }
}
