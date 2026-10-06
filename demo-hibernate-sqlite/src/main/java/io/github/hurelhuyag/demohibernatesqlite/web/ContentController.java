package io.github.hurelhuyag.demohibernatesqlite.web;

import io.github.hurelhuyag.demohibernatesqlite.business.ContentService;
import io.github.hurelhuyag.demohibernatesqlite.views.ContentView;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/contents")
public class ContentController {

    private final ContentService contentService;

    @GetMapping
    public Slice<ContentView> findAll(Pageable pageable) {
        return contentService.findAll(pageable);
    }

    @GetMapping("/{id}")
    public ContentView findById(@PathVariable Long id) {
        return contentService.findById(id);
    }

    @PutMapping("/{id}")
    public ContentView updateText(@PathVariable Long id, @Valid @RequestBody ContentUpdateRequest request) {
        return contentService.updateText(id, request.content());
    }
}
