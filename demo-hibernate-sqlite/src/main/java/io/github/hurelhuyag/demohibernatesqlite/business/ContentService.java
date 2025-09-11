package io.github.hurelhuyag.demohibernatesqlite.business;

import io.github.hurelhuyag.demohibernatesqlite.models.Content;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;

public interface ContentService {

    Slice<Content> findAll(Pageable pageable);
}
