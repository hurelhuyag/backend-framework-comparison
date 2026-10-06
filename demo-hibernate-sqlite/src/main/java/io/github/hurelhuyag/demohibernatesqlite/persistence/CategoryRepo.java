package io.github.hurelhuyag.demohibernatesqlite.persistence;

import io.github.hurelhuyag.demohibernatesqlite.models.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface CategoryRepo extends JpaRepository<Category, Long> {

    @Query("""
        select c from Category c
        left join fetch c.parent p
        left join fetch p.parent
        order by c.id""")
    List<Category> findSorted();
}
