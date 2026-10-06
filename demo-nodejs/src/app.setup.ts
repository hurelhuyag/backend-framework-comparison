import { INestApplication, ValidationPipe } from "@nestjs/common";

/** Global HTTP setup shared by main.ts and the e2e tests, so tests run the real configuration. */
export function configureApp(app: INestApplication): void {
    app.setGlobalPrefix("api");
    app.useGlobalPipes(
        new ValidationPipe({
            whitelist: true, // strip properties without validation decorators
            transform: true, // query strings -> typed DTO instances
        }),
    );
    // Every error is JSON: HttpExceptions (400/404) use Nest's {statusCode, message, error} body,
    // anything unexpected becomes {statusCode: 500, message: "Internal server error"}.
}
