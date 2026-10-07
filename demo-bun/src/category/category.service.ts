import { categoryChain, type CategoryView } from "../common/views";
import { listCategories } from "./category.repository";

export async function getAll(): Promise<CategoryView[]> {
    const rows = await listCategories();

    return rows.map((row: any) => categoryChain([row.category, row.parent, row.grandparent])!);
}
