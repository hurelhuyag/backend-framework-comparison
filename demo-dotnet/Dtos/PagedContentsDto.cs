namespace DemoDotnet.Dtos;

public sealed record PagedContentsDto(int Page, int Size, IReadOnlyList<ContentDto> Contents);
