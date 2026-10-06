package io.github.hurelhuyag.demohibernatesqlite.business;

import io.github.hurelhuyag.demohibernatesqlite.models.Content;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;

import java.util.Optional;

public interface ContentService {

    Slice<Content> findAll(Pageable pageable);

    Optional<Content> findById(Long id);
}
