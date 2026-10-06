using System.Text.Json;
using System.Text.Json.Serialization;
using DemoDotnet.Extensions;
using DemoDotnet.Middlewares;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddPersistence();
builder.Services.AddBusinessServices();

builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        // PascalCase -> snake_case, so the payload matches the other demos (parent_id, category_id).
        options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower;
        options.JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.Never;
    });

// The other demos log at WARN/ERROR; ASP.NET Core defaults to Information and logs every
// request, which would charge this row for work the others are not doing.
builder.Logging.ClearProviders();
builder.Logging.AddSimpleConsole();
builder.Logging.SetMinimumLevel(LogLevel.Warning);

var app = builder.Build();

app.UseMiddleware<ExceptionHandlingMiddleware>();
app.MapControllers();

app.Run();
