package handler

import (
	"log/slog"
	"net/http"

	"github.com/gin-gonic/gin"

	"demo-go/internal/middleware"
)

func NewRouter(log *slog.Logger, categories *CategoryHandler, contents *ContentHandler) *gin.Engine {
	gin.SetMode(gin.ReleaseMode)
	UseJSONFieldNames()

	r := gin.New()
	r.Use(
		middleware.Recovery(log),
		middleware.AccessLog(log),
		ErrorHandler(log),
	)

	r.GET("/healthz", func(c *gin.Context) { c.Status(http.StatusNoContent) })
	categories.Register(r)
	contents.Register(r)

	return r
}
