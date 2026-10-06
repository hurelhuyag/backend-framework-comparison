using DemoDotnet.Data;
using DemoDotnet.Models;
using Microsoft.EntityFrameworkCore;

namespace DemoDotnet.Repositories;

internal sealed class CategoryRepository(DemoContext db) : ICategoryRepository
{
    // Category -> parent -> grandparent: the tree is at most 3 levels deep, so this loads every
    // category's full chain in ONE statement with two LEFT JOINs.
    public async Task<IReadOnlyList<Category>> ListAsync(CancellationToken cancellationToken) =>
        await db.Categories
            .AsNoTracking()
            .Include(category => category.Parent)
            .ThenInclude(parent => parent!.Parent)
            .OrderBy(category => category.Id)
            .ToListAsync(cancellationToken);
}
