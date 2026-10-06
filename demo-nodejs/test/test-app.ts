import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { INestApplication, Logger } from "@nestjs/common";
import { Test } from "@nestjs/testing";
import { AppModule } from "../src/app.module";
import { configureApp } from "../src/app.setup";
import { logLevels } from "../src/common/log-levels";

/**
 * Boots the real AppModule (same global setup as main.ts) against a temp COPY of the repo-root
 * demo.sqlite (built by db/generate.sql), so the original file is never modified.
 */
export async function createTestApp(): Promise<{ app: INestApplication; close: () => Promise<void> }> {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), "demo-nodejs-test-"));
    const copy = path.join(dir, "demo.sqlite");
    fs.copyFileSync(path.resolve(__dirname, "../../demo.sqlite"), copy);
    process.env.DATABASE_URL = `file:${copy}`;

    Logger.overrideLogger(logLevels(process.env.LOG_LEVEL));
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    const app = moduleRef.createNestApplication();
    configureApp(app);
    await app.init();

    return {
        app,
        close: async () => {
            await app.close();
            fs.rmSync(dir, { recursive: true, force: true });
        },
    };
}
