package io.github.hurelhuyag.demohibernatesqlite.business;

import io.github.hurelhuyag.demohibernatesqlite.models.Category;
import io.github.hurelhuyag.demohibernatesqlite.persistence.CategoryRepo;
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
    public List<Category> findAll() {
        return categoryRepo.findSorted();
    }
}
