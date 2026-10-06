package io.github.hurelhuyag.demohibernatesqlite.web;

import io.github.hurelhuyag.demohibernatesqlite.business.CategoryService;
import io.github.hurelhuyag.demohibernatesqlite.views.CategoryView;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RequiredArgsConstructor
@RestController
@RequestMapping("/categories")
public class CategoryController {

    private final CategoryService categoryService;

    @GetMapping
    public List<CategoryView> findAll() {
        return categoryService.findAll();
    }
}
