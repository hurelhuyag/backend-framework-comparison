package io.github.hurelhuyag.demohibernatesqlite.web;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ContentUpdateRequest(
    @NotBlank @Size(max = 1000) String content
) {
}
