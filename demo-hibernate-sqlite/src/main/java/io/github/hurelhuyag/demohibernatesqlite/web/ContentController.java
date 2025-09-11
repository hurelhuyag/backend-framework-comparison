package io.github.hurelhuyag.demohibernatesqlite.web;

import io.github.hurelhuyag.demohibernatesqlite.business.ContentService;
import io.github.hurelhuyag.demohibernatesqlite.models.Content;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.data.web.SortDefault;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RequiredArgsConstructor
@RestController
@RequestMapping("/contents")
public class ContentController {

    private final ContentService contentService;

    @GetMapping
    public Slice<Content> findAll(@PageableDefault Pageable pageable) {
        return contentService.findAll(pageable);
    }
}
