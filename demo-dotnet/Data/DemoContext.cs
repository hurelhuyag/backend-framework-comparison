using DemoDotnet.Models;
using Microsoft.EntityFrameworkCore;

namespace DemoDotnet.Data;

public sealed class DemoContext(DbContextOptions<DemoContext> options) : DbContext(options)
{
    public DbSet<Category> Categories => Set<Category>();

    public DbSet<Content> Contents => Set<Content>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        var category = modelBuilder.Entity<Category>();
        category.ToTable("category");
        category.HasKey(entity => entity.Id);
        category.Property(entity => entity.Id).HasColumnName("id").ValueGeneratedNever();
        category.Property(entity => entity.ParentId).HasColumnName("parent_id");
        category.Property(entity => entity.Name).HasColumnName("name");
        category.HasOne(entity => entity.Parent)
            .WithMany(entity => entity.Children)
            .HasForeignKey(entity => entity.ParentId);

        var content = modelBuilder.Entity<Content>();
        content.ToTable("content");
        content.HasKey(entity => entity.Id);
        content.Property(entity => entity.Id).HasColumnName("id").ValueGeneratedNever();
        content.Property(entity => entity.CategoryId).HasColumnName("category_id");
        content.Property(entity => entity.Text).HasColumnName("content");
        content.HasOne(entity => entity.Category)
            .WithMany()
            .HasForeignKey(entity => entity.CategoryId);
    }
}
