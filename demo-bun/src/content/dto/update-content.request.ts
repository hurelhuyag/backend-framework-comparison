import { z } from "zod";

export const updateContentRequest = z.object({
    content: z.string().min(1).max(1000),
});
