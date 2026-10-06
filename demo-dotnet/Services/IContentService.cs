using DemoDotnet.Dtos;

namespace DemoDotnet.Services;

public interface IContentService
{
    Task<PagedContentsDto> GetPageAsync(PageQuery page, CancellationToken cancellationToken);

    Task<ContentDto?> GetByIdAsync(int id, CancellationToken cancellationToken);

    Task<ContentDto?> UpdateTextAsync(int id, string text, CancellationToken cancellationToken);
}
