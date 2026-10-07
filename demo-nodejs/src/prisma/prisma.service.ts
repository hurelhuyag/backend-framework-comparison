import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from "@nestjs/common";
import { Prisma, PrismaClient } from "@prisma/client";

const DEFAULT_DATABASE_URL = "postgres://bench:bench@127.0.0.1:5432/demo";

/**
 * DATABASE_URL with Prisma's pool size (`connection_limit`) set to DB_POOL_SIZE (default 32),
 * unless the URL already carries an explicit connection_limit.
 */
export function databaseUrl(env: NodeJS.ProcessEnv = process.env): string {
    const url = new URL(env.DATABASE_URL || DEFAULT_DATABASE_URL);
    if (!url.searchParams.has("connection_limit")) {
        url.searchParams.set("connection_limit", env.DB_POOL_SIZE || "32");
    }
    return url.toString();
}

/** The single PrismaClient of the app. Connection string comes from DATABASE_URL (+ DB_POOL_SIZE). */
@Injectable()
export class PrismaService
    extends PrismaClient<Prisma.PrismaClientOptions, "query">
    implements OnModuleInit, OnModuleDestroy
{
    private readonly logger = new Logger(PrismaService.name);

    constructor() {
        // SQL is only emitted (and only costs anything) when the debug level is enabled.
        const sqlLogging = Logger.isLevelEnabled("debug");
        super({ datasourceUrl: databaseUrl(), log: sqlLogging ? [{ emit: "event", level: "query" }] : [] });
        if (sqlLogging) this.$on("query", (e) => this.logger.debug(e.query));
    }

    async onModuleInit(): Promise<void> {
        await this.$connect();
    }

    async onModuleDestroy(): Promise<void> {
        await this.$disconnect();
    }
}
