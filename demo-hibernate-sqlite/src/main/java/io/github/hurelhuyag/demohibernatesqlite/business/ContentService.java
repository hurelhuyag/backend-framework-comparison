package io.github.hurelhuyag.demohibernatesqlite.business;

import io.github.hurelhuyag.demohibernatesqlite.views.ContentView;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;

public interface ContentService {

    Slice<ContentView> findAll(Pageable pageable);

    /// @throws ContentNotFoundException when no content has this id
    ContentView findById(Long id);

    /// @throws ContentNotFoundException when no content has this id
    ContentView updateText(Long id, String text);
}
