namespace DemoDotnet.Models;

public sealed class Category
{
    public int Id { get; set; }

    public int? ParentId { get; set; }

    public string Name { get; set; } = "";

    public Category? Parent { get; set; }

    public List<Category> Children { get; } = [];
}
