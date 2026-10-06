using DemoDotnet.Dtos;
using DemoDotnet.Repositories;
using MapsterMapper;

namespace DemoDotnet.Services;

internal sealed class CategoryService(ICategoryRepository categories, IMapper mapper) : ICategoryService
{
    public async Task<IReadOnlyList<CategoryDto>> GetAllAsync(CancellationToken cancellationToken) =>
        mapper.Map<List<CategoryDto>>(await categories.ListAsync(cancellationToken));
}
