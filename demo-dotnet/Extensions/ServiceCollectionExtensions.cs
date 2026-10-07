using System.Reflection;
using DemoDotnet.Data;
using DemoDotnet.Repositories;
using DemoDotnet.Services;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace DemoDotnet.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddPersistence(this IServiceCollection services)
    {
        var connectionString = DatabaseSettings.ConnectionString();

        services.AddDbContextPool<DemoContext>(options => options.UseNpgsql(connectionString));
        services.AddScoped<IContentRepository, ContentRepository>();
        services.AddScoped<ICategoryRepository, CategoryRepository>();

        return services;
    }

    public static IServiceCollection AddBusinessServices(this IServiceCollection services)
    {
        var assembly = Assembly.GetExecutingAssembly();

        services.AddScoped<IContentService, ContentService>();
        services.AddScoped<ICategoryService, CategoryService>();
        services.AddValidatorsFromAssembly(assembly);

        var typeAdapterConfig = TypeAdapterConfig.GlobalSettings;
        typeAdapterConfig.Scan(assembly);
        services.AddSingleton(typeAdapterConfig);
        services.AddScoped<IMapper, ServiceMapper>();

        return services;
    }
}
