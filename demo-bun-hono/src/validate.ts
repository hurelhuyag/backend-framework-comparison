import { zValidator } from "@hono/zod-validator";
import type { ValidationTargets } from "hono";
import type { ZodType } from "zod";

/** zValidator whose failures use the app's error body: 400 with one "<field>: <issue>" per problem. */
export const validate = <T extends ZodType, Target extends keyof ValidationTargets>(target: Target, schema: T) =>
    zValidator(target, schema, (result, c) => {
        if (result.success) return;
        const message = result.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`);
        return c.json({ statusCode: 400, message, error: "Bad Request" }, 400);
    });
