package handler

import (
	"errors"
	"log/slog"
	"net/http"
	"reflect"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/gin-gonic/gin/binding"
	"github.com/go-playground/validator/v10"

	"demo-go/internal/service"
)

type errorResponse struct {
	Error   string       `json:"error"`
	Details []fieldError `json:"details,omitempty"`
}

type fieldError struct {
	Field string `json:"field"`
	Rule  string `json:"rule"`
}

// ErrorHandler is the single place that turns errors recorded with c.Error into HTTP
// responses, so handlers never pick status codes for failures themselves.
func ErrorHandler(log *slog.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()

		last := c.Errors.Last()
		if last == nil || c.Writer.Written() {
			return
		}

		var invalid validator.ValidationErrors
		switch {
		case errors.As(last.Err, &invalid):
			details := make([]fieldError, len(invalid))
			for i, fe := range invalid {
				details[i] = fieldError{Field: fe.Field(), Rule: fe.Tag()}
			}
			c.JSON(http.StatusBadRequest, errorResponse{Error: "validation_failed", Details: details})
		case last.IsType(gin.ErrorTypeBind):
			c.JSON(http.StatusBadRequest, errorResponse{Error: "bad_request"})
		case errors.Is(last.Err, service.ErrContentNotFound):
			c.JSON(http.StatusNotFound, errorResponse{Error: "content_not_found"})
		default:
			log.ErrorContext(c.Request.Context(), "request failed",
				"method", c.Request.Method, "path", c.FullPath(), "err", last.Err)
			c.JSON(http.StatusInternalServerError, errorResponse{Error: "internal_error"})
		}
	}
}

// UseJSONFieldNames makes validation errors report `content` rather than `Content`.
func UseJSONFieldNames() {
	v, ok := binding.Validator.Engine().(*validator.Validate)
	if !ok {
		return
	}
	v.RegisterTagNameFunc(func(f reflect.StructField) string {
		for _, tag := range []string{"json", "form", "uri"} {
			if name, _, _ := strings.Cut(f.Tag.Get(tag), ","); name != "" && name != "-" {
				return name
			}
		}
		return f.Name
	})
}
