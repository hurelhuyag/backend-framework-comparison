package io.github.hurelhuyag.demohibernatesqlite.persistence;

import io.github.hurelhuyag.demohibernatesqlite.models.Category;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface CategoryRepo extends JpaRepository<Category, Long> {

    @Query("select c from Category c order by c.id")
    @EntityGraph("Category.withParent")
    List<Category> findSorted();
}
