import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function GET() {
    const categories = await prisma.category.findMany({
        orderBy: { id: "asc" },
        include: {
            parent: true
        }
    });
    return NextResponse.json({ data: categories });
}