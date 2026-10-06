package io.github.hurelhuyag.demohibernatesqlite.business;

import io.github.hurelhuyag.demohibernatesqlite.models.Content;
import io.github.hurelhuyag.demohibernatesqlite.persistence.ContentRepo;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
@Transactional
@RequiredArgsConstructor
public class SimpleContentService implements ContentService {

    private final ContentRepo contentRepo;

    @Transactional(readOnly = true)
    @Override
    public Slice<Content> findAll(Pageable pageable) {
        return contentRepo.findSorted(pageable);
    }

    @Transactional(readOnly = true)
    @Override
    public Optional<Content> findById(Long id) {
        return contentRepo.findDetail(id);
    }

    // Rewrites only the text, so the row count never changes and reads stay comparable.
    // Hibernate dirty-checking flushes the change when the transaction commits.
    @Override
    public Optional<Content> updateText(Long id, String text) {
        return contentRepo.findById(id).map(content -> {
            content.setContent(text);
            return content;
        });
    }
}
