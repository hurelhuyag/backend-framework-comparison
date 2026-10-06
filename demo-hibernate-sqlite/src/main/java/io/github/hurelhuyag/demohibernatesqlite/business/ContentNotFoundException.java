package io.github.hurelhuyag.demohibernatesqlite.business;

public class ContentNotFoundException extends RuntimeException {

    public ContentNotFoundException(Long id) {
        super("Content " + id + " not found");
    }
}
