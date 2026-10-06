package io.github.hurelhuyag.demohibernatesqlite.business;

import io.github.hurelhuyag.demohibernatesqlite.models.Category;

import java.util.List;

public interface CategoryService {

    List<Category> findAll();
}
