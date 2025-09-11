import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function GET(req: NextRequest) {
    const { searchParams } = new URL(req.url);
    const page = Math.max(1, Number(searchParams.get("page") ?? 1));
    const pageSize = Math.min(100, Number(searchParams.get("pageSize") ?? 20));

    const items = await prisma.content.findMany({
        skip: (page - 1) * pageSize,
        take: pageSize,
        orderBy: { id: "asc" },
        include: {
            category: {
                include: {
                    parent: true
                }
            },
        },
    });

    return NextResponse.json({
        meta: { page, pageSize },
        data: items,
    });
}