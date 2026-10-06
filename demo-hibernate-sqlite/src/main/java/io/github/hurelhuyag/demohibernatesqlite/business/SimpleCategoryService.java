package io.github.hurelhuyag.demohibernatesqlite.business;

import io.github.hurelhuyag.demohibernatesqlite.persistence.CategoryRepo;
import io.github.hurelhuyag.demohibernatesqlite.views.CategoryView;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
@RequiredArgsConstructor
public class SimpleCategoryService implements CategoryService {

    private final CategoryRepo categoryRepo;

    @Transactional(readOnly = true)
    @Override
    public List<CategoryView> findAll() {
        return categoryRepo.findSorted().stream()
            .map(CategoryView::new)
            .toList();
    }
}
