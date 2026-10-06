import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from "@nestjs/common";
import { Prisma, PrismaClient } from "@prisma/client";

/** The single PrismaClient of the app. Connection string comes from DATABASE_URL. */
@Injectable()
export class PrismaService
    extends PrismaClient<Prisma.PrismaClientOptions, "query">
    implements OnModuleInit, OnModuleDestroy
{
    private readonly logger = new Logger(PrismaService.name);

    constructor() {
        // SQL is only emitted (and only costs anything) when the debug level is enabled.
        const sqlLogging = Logger.isLevelEnabled("debug");
        super({ log: sqlLogging ? [{ emit: "event", level: "query" }] : [] });
        if (sqlLogging) this.$on("query", (e) => this.logger.debug(e.query));
    }

    async onModuleInit(): Promise<void> {
        await this.$connect();
    }

    async onModuleDestroy(): Promise<void> {
        await this.$disconnect();
    }
}
