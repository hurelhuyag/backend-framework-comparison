using DemoDotnet.Models;

namespace DemoDotnet.Repositories;

// Spring Data generates this layer from an interface; in .NET it is written by hand.
public interface IContentRepository
{
    Task<IReadOnlyList<Content>> ListAsync(int skip, int take, CancellationToken cancellationToken);

    Task<Content?> FindAsync(int id, CancellationToken cancellationToken);

    Task<Content?> FindForUpdateAsync(int id, CancellationToken cancellationToken);

    Task SaveChangesAsync(CancellationToken cancellationToken);
}
