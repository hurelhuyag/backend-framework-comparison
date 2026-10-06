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

// Rewrites only the text, so the row count never changes and reads stay comparable.
export async function PUT(req: Request) {
    const url = new URL(req.url);
    const pathSegments = url.pathname.split("/");
    const contentId = Number(pathSegments[pathSegments.length - 1]);

    if (Number.isNaN(contentId)) {
        return NextResponse.json({ error: "Invalid id" }, { status: 400 });
    }

    const body = await req.json().catch(() => null);

    if (!body || typeof body.content !== "string" || body.content.length === 0) {
        return NextResponse.json({ error: "content is required" }, { status: 400 });
    }

    try {
        const content = await prisma.content.update({
            where: { id: contentId },
            data: { content: body.content },
        });

        return NextResponse.json({ data: content });
    } catch {
        return NextResponse.json({ error: "Not found" }, { status: 404 });
    }
}
