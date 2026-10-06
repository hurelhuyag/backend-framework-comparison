namespace DemoDotnet.Dtos;

public sealed record ContentDto(int Id, int? CategoryId, string Content, CategoryDto? Category);
