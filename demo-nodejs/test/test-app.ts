import { INestApplication, Logger } from "@nestjs/common";
import { Test } from "@nestjs/testing";
import { AppModule } from "../src/app.module";
import { configureApp } from "../src/app.setup";
import { logLevels } from "../src/common/log-levels";

/**
 * Boots the real AppModule (same global setup as main.ts) against the PostgreSQL database in
 * DATABASE_URL (test.sh hands each run a fresh clone of demo_template). The one write the tests
 * make is undone by api.test.ts.
 */
export async function createTestApp(): Promise<{ app: INestApplication; close: () => Promise<void> }> {
    Logger.overrideLogger(logLevels(process.env.LOG_LEVEL));
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    const app = moduleRef.createNestApplication();
    configureApp(app);
    await app.init();

    return { app, close: () => app.close() };
}
