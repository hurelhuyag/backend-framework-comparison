namespace DemoDotnet.Models;

// `Text` rather than `Content`: a property may not share the name of its enclosing type.
// It is mapped to the `content` column in DemoContext.
public sealed class Content
{
    public int Id { get; set; }

    public int? CategoryId { get; set; }

    public string Text { get; set; } = "";

    public Category? Category { get; set; }
}
