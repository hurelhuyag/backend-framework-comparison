import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function GET(req: Request) {
    const url = new URL(req.url);
    const pathSegments = url.pathname.split("/");
    const idStr = pathSegments[pathSegments.length - 1];
    const contentId = Number(idStr);

    if (Number.isNaN(contentId)) {
        return NextResponse.json({ error: "Invalid id" }, { status: 400 });
    }

    const content = await prisma.content.findUnique({
        where: { id: contentId },
        include: { category: true },
    });

    if (!content) {
        return NextResponse.json({ error: "Not found" }, { status: 404 });
    }

    return NextResponse.json({ data: content });
}
