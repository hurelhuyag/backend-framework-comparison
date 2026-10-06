using DemoDotnet.Dtos;

namespace DemoDotnet.Services;

public interface ICategoryService
{
    Task<IReadOnlyList<CategoryDto>> GetAllAsync(CancellationToken cancellationToken);
}
