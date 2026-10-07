import "reflect-metadata";
import cluster from "node:cluster";
import { Logger } from "@nestjs/common";
import { NestFactory } from "@nestjs/core";
import { AppModule } from "./app.module";
import { configureApp } from "./app.setup";
import { logLevels } from "./common/log-levels";

// One JavaScript thread per process, so the primary forks WORKERS processes (default 4, one per
// core) with node:cluster and they share the port. Each worker gets an equal share of the
// DB_POOL_SIZE connection budget, which PrismaService turns into its connection_limit.
const workers = Math.max(1, Number(process.env.WORKERS ?? 4));
const port = Number(process.env.PORT ?? 3000);

async function bootstrap(): Promise<void> {
    const app = await NestFactory.create(AppModule, { logger: logLevels(process.env.LOG_LEVEL) });
    configureApp(app);
    // SIGTERM/SIGINT -> onModuleDestroy hooks (PrismaService disconnects) -> exit.
    app.enableShutdownHooks();

    await app.listen(port);
    new Logger("Bootstrap").log(`Worker ${process.pid} listening on port ${port}`);
}

function supervise(): void {
    Logger.overrideLogger(logLevels(process.env.LOG_LEVEL));
    const logger = new Logger("Cluster");
    const poolSize = Math.max(1, Math.floor(Number(process.env.DB_POOL_SIZE ?? 32) / workers));
    let stopping = false;
    const stopAll = () => {
        stopping = true;
        for (const w of Object.values(cluster.workers ?? {})) w?.kill("SIGTERM");
    };

    for (let i = 0; i < workers; i++) cluster.fork({ DB_POOL_SIZE: String(poolSize) });
    // A worker that dies takes the whole server down, so the container restarts cleanly.
    cluster.on("exit", (worker, code) => {
        if (stopping) return;
        logger.error(`Worker ${worker.process.pid} exited with code ${code}`);
        process.exitCode = 1;
        stopAll();
    });
    process.on("SIGINT", stopAll);
    process.on("SIGTERM", stopAll);
}

if (cluster.isPrimary) supervise();
else void bootstrap();
