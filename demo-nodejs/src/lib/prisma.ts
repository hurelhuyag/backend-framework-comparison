import { PrismaClient } from "@prisma/client";

const globalForPrisma = global as unknown as { prisma?: PrismaClient };

export const prisma = globalForPrisma.prisma ?? new PrismaClient({ log: ["error"] });

// run once when prisma client is first imported
(async () => {
    try {
        await prisma.$queryRaw`PRAGMA journal_mode=WAL;`;
        await prisma.$queryRaw`PRAGMA synchronous=NORMAL;`;
        console.log("SQLite WAL mode enabled");
    } catch (e) {
        console.error("Failed to enable WAL mode", e);
    }
})();

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;