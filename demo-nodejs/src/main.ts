import "reflect-metadata";
import { Logger } from "@nestjs/common";
import { NestFactory } from "@nestjs/core";
import { AppModule } from "./app.module";
import { configureApp } from "./app.setup";
import { logLevels } from "./common/log-levels";

async function bootstrap(): Promise<void> {
    const app = await NestFactory.create(AppModule, { logger: logLevels(process.env.LOG_LEVEL) });
    configureApp(app);
    // SIGTERM/SIGINT -> onModuleDestroy hooks (PrismaService disconnects) -> exit.
    app.enableShutdownHooks();

    const port = Number(process.env.PORT ?? 3000);
    await app.listen(port);
    new Logger("Bootstrap").log(`Listening on port ${port}`);
}

void bootstrap();
