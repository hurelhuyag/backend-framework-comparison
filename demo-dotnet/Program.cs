using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

var dbPath = Environment.GetEnvironmentVariable("DEMO_DB") ?? "demo.sqlite";
builder.Services.AddDbContextPool<DemoContext>(options => options.UseSqlite($"Data Source={dbPath}"));

// PascalCase -> snake_case, so the payload matches the other demos (parent_id, category_id).
builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower;
    options.SerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.Never;
});

// The other demos log at WARN/ERROR; ASP.NET Core defaults to Information and logs every
// request, which would charge this row for work the others are not doing.
builder.Logging.ClearProviders();
builder.Logging.AddSimpleConsole();
builder.Logging.SetMinimumLevel(LogLevel.Warning);

var app = builder.Build();

// Mounted at both /... and /api/... so either `ab` command shape in the root README works.
foreach (var prefix in new[] { "", "/api" })
{
    app.MapGet($"{prefix}/contents", async (DemoContext db, HttpRequest request) =>
    {
        var (page, size) = Pagination(request);

        var rows = await db.Contents
            .AsNoTracking()
            .Include(content => content.Category!)
            .ThenInclude(category => category.Parent)
            .OrderBy(content => content.Id)
            .Skip((page - 1) * size)
            .Take(size)
            .ToListAsync();

        return Results.Ok(new ContentsResponse(
            page,
            size,
            rows.Select(content => new ContentView(
                content.Id,
                content.CategoryId,
                content.Text,
                content.Category is null ? null : new CategoryView(
                    content.Category.Id,
                    content.Category.ParentId,
                    content.Category.Name,
                    content.Category.Parent is null ? null : new CategoryView(
                        content.Category.Parent.Id,
                        content.Category.Parent.ParentId,
                        content.Category.Parent.Name,
                        null
                    )
                )
            )).ToList()
        ));
    });

    app.MapGet($"{prefix}/contents/{{id:int}}", async (DemoContext db, int id) =>
    {
        var content = await db.Contents
            .AsNoTracking()
            .Include(c => c.Category!)
            .ThenInclude(category => category.Parent)
            .FirstOrDefaultAsync(c => c.Id == id);

        if (content is null)
        {
            return Results.NotFound("content not found");
        }

        return Results.Ok(new ContentView(
            content.Id,
            content.CategoryId,
            content.Text,
            content.Category is null ? null : new CategoryView(
                content.Category.Id,
                content.Category.ParentId,
                content.Category.Name,
                content.Category.Parent is null ? null : new CategoryView(
                    content.Category.Parent.Id,
                    content.Category.Parent.ParentId,
                    content.Category.Parent.Name,
                    null
                )
            )
        ));
    });

    app.MapGet($"{prefix}/categories", async (DemoContext db) =>
    {
        var categories = await db.Categories
            .AsNoTracking()
            .Include(category => category.Parent)
            .OrderBy(category => category.Id)
            .ToListAsync();

        return Results.Ok(categories.Select(category => new CategoryView(
            category.Id,
            category.ParentId,
            category.Name,
            category.Parent is null ? null : new CategoryView(
                category.Parent.Id,
                category.Parent.ParentId,
                category.Parent.Name,
                null
            )
        )).ToList());
    });
}

app.Run();

// Same defaults as the Django/NextJS demos: page 1, 20 rows, hard cap of 100. The alternate
// spellings keep the single benchmark URL shape working across every demo.
static (int Page, int Size) Pagination(HttpRequest request)
{
    var page = 1;
    var size = 20;

    if (int.TryParse(request.Query["page"], out var p) && p > 0)
    {
        page = p;
    }

    foreach (var key in new[] { "size", "page_size", "pageSize" })
    {
        if (int.TryParse(request.Query[key], out var s) && s > 0)
        {
            size = Math.Min(s, 100);
            break;
        }
    }

    return (page, size);
}

public sealed class DemoContext(DbContextOptions<DemoContext> options) : DbContext(options)
{
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Content> Contents => Set<Content>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        var category = modelBuilder.Entity<Category>();
        category.ToTable("category");
        category.HasKey(entity => entity.Id);
        category.Property(entity => entity.Id).HasColumnName("id").ValueGeneratedNever();
        category.Property(entity => entity.ParentId).HasColumnName("parent_id");
        category.Property(entity => entity.Name).HasColumnName("name");
        category.HasOne(entity => entity.Parent)
            .WithMany(entity => entity.Children)
            .HasForeignKey(entity => entity.ParentId);

        var content = modelBuilder.Entity<Content>();
        content.ToTable("content");
        content.HasKey(entity => entity.Id);
        content.Property(entity => entity.Id).HasColumnName("id").ValueGeneratedNever();
        content.Property(entity => entity.CategoryId).HasColumnName("category_id");
        content.Property(entity => entity.Text).HasColumnName("content");
        content.HasOne(entity => entity.Category)
            .WithMany()
            .HasForeignKey(entity => entity.CategoryId);
    }
}

public sealed class Category
{
    public int Id { get; set; }
    public int? ParentId { get; set; }
    public string Name { get; set; } = "";
    public Category? Parent { get; set; }
    public List<Category> Children { get; } = [];
}

// `Text` rather than `Content`: a property may not share the name of its enclosing type.
public sealed class Content
{
    public int Id { get; set; }
    public int? CategoryId { get; set; }
    public string Text { get; set; } = "";
    public Category? Category { get; set; }
}

public record CategoryView(int Id, int? ParentId, string Name, CategoryView? Parent);

public record ContentView(int Id, int? CategoryId, string Content, CategoryView? Category);

public record ContentsResponse(int Page, int Size, List<ContentView> Contents);
