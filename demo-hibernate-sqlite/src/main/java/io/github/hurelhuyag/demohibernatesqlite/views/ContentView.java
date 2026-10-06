package io.github.hurelhuyag.demohibernatesqlite.views;

import io.github.hurelhuyag.demohibernatesqlite.models.Content;

public record ContentView(Long id, CategoryView category, String content) {

    public ContentView(Content content) {
        this(content.getId(), CategoryView.of(content.getCategory()), content.getContent());
    }
}
