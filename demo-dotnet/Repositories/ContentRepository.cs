using DemoDotnet.Data;
using DemoDotnet.Models;
using Microsoft.EntityFrameworkCore;

namespace DemoDotnet.Repositories;

internal sealed class ContentRepository(DemoContext db) : IContentRepository
{
    // Include + ThenInclude resolves content -> category -> parent -> grandparent (the full chain of
    // the 3-level category tree) in ONE statement with three LEFT JOINs, because EF Core aliases the
    // self-referencing joins. No COUNT(*) is issued.
    public async Task<IReadOnlyList<Content>> ListAsync(
        int skip,
        int take,
        CancellationToken cancellationToken) =>
        await db.Contents
            .AsNoTracking()
            .Include(content => content.Category!)
            .ThenInclude(category => category.Parent)
            .ThenInclude(parent => parent!.Parent)
            .OrderBy(content => content.Id)
            .Skip(skip)
            .Take(take)
            .ToListAsync(cancellationToken);

    public Task<Content?> FindAsync(int id, CancellationToken cancellationToken) =>
        db.Contents
            .AsNoTracking()
            .Include(content => content.Category!)
            .ThenInclude(category => category.Parent)
            .ThenInclude(parent => parent!.Parent)
            .FirstOrDefaultAsync(content => content.Id == id, cancellationToken);

    // Tracked, because the service mutates and saves it.
    public Task<Content?> FindForUpdateAsync(int id, CancellationToken cancellationToken) =>
        db.Contents.FirstOrDefaultAsync(content => content.Id == id, cancellationToken);

    public Task SaveChangesAsync(CancellationToken cancellationToken) =>
        db.SaveChangesAsync(cancellationToken);
}
