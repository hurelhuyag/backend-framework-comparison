using DemoDotnet.Dtos;
using DemoDotnet.Models;
using Mapster;

namespace DemoDotnet.Mapping;

// Mapster replaces hand-written entity -> DTO mapping, registered once at startup.
public sealed class MappingConfig : IRegister
{
    public void Register(TypeAdapterConfig config)
    {
        config.NewConfig<Category, CategoryDto>()
            .Map(dest => dest.Parent, src => src.Parent == null
                ? null
                : new CategoryDto(src.Parent.Id, src.Parent.ParentId, src.Parent.Name, null));

        config.NewConfig<Content, ContentDto>()
            .Map(dest => dest.Content, src => src.Text);
    }
}
