namespace DemoDotnet.Dtos;

public sealed record CategoryDto(int Id, int? ParentId, string Name, CategoryDto? Parent);
