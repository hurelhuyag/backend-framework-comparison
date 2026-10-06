package io.github.hurelhuyag.demohibernatesqlite.persistence;

import io.github.hurelhuyag.demohibernatesqlite.models.Content;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface ContentRepo extends JpaRepository<Content, Long> {

    @Query("select c from Content c order by c.id desc")
    @EntityGraph("Content.withCategory")
    Slice<Content> findSorted(Pageable pageable);

    @Query("select c from Content c where c.id = :id")
    @EntityGraph("Content.withCategory")
    Optional<Content> findDetail(@Param("id") Long id);
}
