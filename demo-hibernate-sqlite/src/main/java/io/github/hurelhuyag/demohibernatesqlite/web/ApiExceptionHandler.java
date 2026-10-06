package io.github.hurelhuyag.demohibernatesqlite.web;

import io.github.hurelhuyag.demohibernatesqlite.business.ContentNotFoundException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import java.util.List;
import java.util.Map;

/// Turns every error into an RFC 9457 ProblemDetail. The base class already covers Spring MVC's
/// own exceptions (malformed JSON, type mismatches, unsupported methods, ...).
@RestControllerAdvice
public class ApiExceptionHandler extends ResponseEntityExceptionHandler {

    @ExceptionHandler(ContentNotFoundException.class)
    ProblemDetail handleNotFound(ContentNotFoundException e) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, e.getMessage());
    }

    /// Adds the failed fields, which the default "Invalid request content." detail leaves out.
    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(
        MethodArgumentNotValidException e, HttpHeaders headers, HttpStatusCode status, WebRequest request
    ) {
        List<Map<String, String>> errors = e.getFieldErrors().stream()
            .map(error -> Map.of("field", error.getField(), "message", String.valueOf(error.getDefaultMessage())))
            .toList();
        e.getBody().setProperty("errors", errors);
        return handleExceptionInternal(e, e.getBody(), headers, status, request);
    }
}
