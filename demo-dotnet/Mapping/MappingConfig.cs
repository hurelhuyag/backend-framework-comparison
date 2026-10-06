using DemoDotnet.Dtos;
using DemoDotnet.Models;
using Mapster;

namespace DemoDotnet.Mapping;

// Mapster replaces hand-written entity -> DTO mapping, registered once at startup.
public sealed class MappingConfig : IRegister
{
    public void Register(TypeAdapterConfig config)
    {
        // Category -> CategoryDto needs no rule: Mapster maps Parent recursively, so the DTO carries
        // whatever chain the repository eagerly loaded (up to the root). No lazy loading is involved.
        config.NewConfig<Content, ContentDto>()
            .Map(dest => dest.Content, src => src.Text);
    }
}
