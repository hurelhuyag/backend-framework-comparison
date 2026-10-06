package io.github.hurelhuyag.demohibernatesqlite.business;

import io.github.hurelhuyag.demohibernatesqlite.views.CategoryView;

import java.util.List;

public interface CategoryService {

    List<CategoryView> findAll();
}
