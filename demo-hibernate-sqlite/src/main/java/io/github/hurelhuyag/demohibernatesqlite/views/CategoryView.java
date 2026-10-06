package io.github.hurelhuyag.demohibernatesqlite.views;

import io.github.hurelhuyag.demohibernatesqlite.models.Category;
import org.hibernate.Hibernate;

public record CategoryView(Long id, CategoryView parent, String name) {

    // Follows only associations the query already fetched, so mapping never fires a lazy load.
    public CategoryView(Category category) {
        this(category.getId(), of(category.getParent()), category.getName());
    }

    static CategoryView of(Category category) {
        return category != null && Hibernate.isInitialized(category) ? new CategoryView(category) : null;
    }
}
