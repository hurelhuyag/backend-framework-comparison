package io.github.hurelhuyag.demohibernatesqlite.persistence;

import io.github.hurelhuyag.demohibernatesqlite.models.Content;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface ContentRepo extends JpaRepository<Content, Long> {

    // Explicit fetch joins load the full 3-level category chain in one statement. A nested
    // entity graph can't do this: Hibernate sees parent.parent as circular and stops joining.
    @Query("""
        select c from Content c
        left join fetch c.category cat
        left join fetch cat.parent p
        left join fetch p.parent
        order by c.id desc""")
    Slice<Content> findSorted(Pageable pageable);

    @Query("""
        select c from Content c
        left join fetch c.category cat
        left join fetch cat.parent p
        left join fetch p.parent
        where c.id = :id""")
    Optional<Content> findDetail(@Param("id") Long id);

    // A single UPDATE, so the transaction takes the write lock on its first statement.
    // Loading the entity first and letting dirty-checking flush at commit starts the
    // transaction with a READ lock and then has to upgrade it, which SQLite refuses with
    // SQLITE_BUSY_SNAPSHOT the moment another writer has committed in between - and that
    // failure is not waitable, so busy_timeout cannot help.
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("update Content c set c.content = :text where c.id = :id")
    int updateText(@Param("id") Long id, @Param("text") String text);
}
