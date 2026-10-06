using DemoDotnet.Data;
using DemoDotnet.Models;
using Microsoft.EntityFrameworkCore;

namespace DemoDotnet.Repositories;

internal sealed class CategoryRepository(DemoContext db) : ICategoryRepository
{
    public async Task<IReadOnlyList<Category>> ListAsync(CancellationToken cancellationToken) =>
        await db.Categories
            .AsNoTracking()
            .Include(category => category.Parent)
            .OrderBy(category => category.Id)
            .ToListAsync(cancellationToken);
}
