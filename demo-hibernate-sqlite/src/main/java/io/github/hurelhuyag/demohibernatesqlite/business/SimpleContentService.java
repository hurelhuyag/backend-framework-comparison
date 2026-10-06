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
}
