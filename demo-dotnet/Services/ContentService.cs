using DemoDotnet.Dtos;
using DemoDotnet.Repositories;
using MapsterMapper;

namespace DemoDotnet.Services;

internal sealed class ContentService(IContentRepository contents, IMapper mapper) : IContentService
{
    public async Task<PagedContentsDto> GetPageAsync(PageQuery page, CancellationToken cancellationToken)
    {
        var rows = await contents.ListAsync(page.Skip, page.ResolvedSize, cancellationToken);

        return new PagedContentsDto(
            page.ResolvedPage,
            page.ResolvedSize,
            mapper.Map<List<ContentDto>>(rows)
        );
    }

    public async Task<ContentDto?> GetByIdAsync(int id, CancellationToken cancellationToken)
    {
        var content = await contents.FindAsync(id, cancellationToken);

        return content is null ? null : mapper.Map<ContentDto>(content);
    }

    // Rewrites only the text, so the row count never changes and reads stay comparable.
    public async Task<ContentDto?> UpdateTextAsync(int id, string text, CancellationToken cancellationToken)
    {
        var content = await contents.FindForUpdateAsync(id, cancellationToken);

        if (content is null)
        {
            return null;
        }

        content.Text = text;
        await contents.SaveChangesAsync(cancellationToken);

        return mapper.Map<ContentDto>(content);
    }
}
