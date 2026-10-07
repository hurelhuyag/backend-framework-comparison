import { contentView, type ContentView } from "../common/views";
import { findContent, listContents, updateContentText } from "./content.repository";

export async function getPage(offset: number, limit: number): Promise<ContentView[]> {
    const rows = await listContents(offset, limit);

    return rows.map((row: any) => contentView(row.content, [row.category, row.parent, row.grandparent]));
}

export async function getById(id: number): Promise<ContentView | null> {
    const [row] = await findContent(id);

    return row === undefined
        ? null
        : contentView(row.content, [row.category, row.parent, row.grandparent]);
}

export async function updateText(id: number, text: string): Promise<ContentView | null> {
    const updated = await updateContentText(id, text);

    return updated.length === 0 ? null : getById(id);
}
