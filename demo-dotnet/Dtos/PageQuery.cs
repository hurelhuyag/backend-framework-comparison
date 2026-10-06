using Microsoft.AspNetCore.Mvc;

namespace DemoDotnet.Dtos;

// Accepts size, page_size and pageSize so one benchmark URL shape works across demos.
public sealed class PageQuery
{
    public const int DefaultSize = 20;
    public const int MaxSize = 100;

    [FromQuery(Name = "page")]
    public int? Page { get; init; }

    [FromQuery(Name = "size")]
    public int? Size { get; init; }

    [FromQuery(Name = "page_size")]
    public int? PageSizeSnake { get; init; }

    [FromQuery(Name = "pageSize")]
    public int? PageSizeCamel { get; init; }

    public int ResolvedPage => Page > 0 ? Page.Value : 1;

    public int ResolvedSize
    {
        get
        {
            var requested = Size ?? PageSizeSnake ?? PageSizeCamel ?? DefaultSize;
            return requested > 0 ? Math.Min(requested, MaxSize) : DefaultSize;
        }
    }

    public int Skip => (ResolvedPage - 1) * ResolvedSize;
}
