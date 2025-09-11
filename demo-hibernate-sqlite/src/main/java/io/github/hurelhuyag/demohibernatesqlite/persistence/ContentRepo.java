package io.github.hurelhuyag.demohibernatesqlite.persistence;

import io.github.hurelhuyag.demohibernatesqlite.models.Content;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ContentRepo extends JpaRepository<Content, Long> {

    @Query("select c from Content c order by c.id desc")
    @EntityGraph("Content.withCategory")
    Slice<Content> findSorted(Pageable pageable);
}
