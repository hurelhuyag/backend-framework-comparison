using DemoDotnet.Models;

namespace DemoDotnet.Repositories;

public interface ICategoryRepository
{
    Task<IReadOnlyList<Category>> ListAsync(CancellationToken cancellationToken);
}
