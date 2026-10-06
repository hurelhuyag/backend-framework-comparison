// Package middleware holds cross-cutting HTTP concerns that are not tied to any one handler.
package middleware

import (
	"context"
	"log/slog"
	"net/http"
	"runtime/debug"
	"time"

	"github.com/gin-gonic/gin"
)

// Recovery turns a panic into a logged JSON 500 instead of a dropped connection.
func Recovery(log *slog.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if rec := recover(); rec != nil {
				log.ErrorContext(c.Request.Context(), "panic recovered",
					"method", c.Request.Method, "path", c.Request.URL.Path,
					"panic", rec, "stack", string(debug.Stack()))
				c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{"error": "internal_error"})
			}
		}()
		c.Next()
	}
}

// AccessLog writes one structured line per request at DEBUG. At the default WARN level the
// Enabled check short-circuits it, matching the other demos, which don't log requests either.
func AccessLog(log *slog.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		if !log.Enabled(context.Background(), slog.LevelDebug) {
			c.Next()
			return
		}
		start := time.Now()
		c.Next()
		log.DebugContext(c.Request.Context(), "request",
			"method", c.Request.Method,
			"path", c.Request.URL.Path,
			"status", c.Writer.Status(),
			"bytes", c.Writer.Size(),
			"duration", time.Since(start),
			"client_ip", c.ClientIP())
	}
}
