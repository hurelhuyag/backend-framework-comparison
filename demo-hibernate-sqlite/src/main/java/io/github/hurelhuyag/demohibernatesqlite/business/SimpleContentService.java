package io.github.hurelhuyag.demohibernatesqlite.business;

import io.github.hurelhuyag.demohibernatesqlite.persistence.ContentRepo;
import io.github.hurelhuyag.demohibernatesqlite.views.ContentView;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
@RequiredArgsConstructor
public class SimpleContentService implements ContentService {

    private final ContentRepo contentRepo;

    @Transactional(readOnly = true)
    @Override
    public Slice<ContentView> findAll(Pageable pageable) {
        return contentRepo.findSorted(pageable).map(ContentView::new);
    }

    @Transactional(readOnly = true)
    @Override
    public ContentView findById(Long id) {
        return contentRepo.findDetail(id)
            .map(ContentView::new)
            .orElseThrow(() -> new ContentNotFoundException(id));
    }

    // Rewrites only the text, so the row count never changes and reads stay comparable.
    // Hibernate dirty-checking flushes the change when the transaction commits.
    @Override
    public ContentView updateText(Long id, String text) {
        var content = contentRepo.findById(id).orElseThrow(() -> new ContentNotFoundException(id));
        content.setContent(text);
        return new ContentView(content);
    }
}
