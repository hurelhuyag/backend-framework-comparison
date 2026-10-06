package handler

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"

	"demo-go/internal/model"
)

type CategoryService interface {
	FindAll(ctx context.Context) ([]model.Category, error)
}

type CategoryHandler struct {
	categories CategoryService
}

func NewCategoryHandler(categories CategoryService) *CategoryHandler {
	return &CategoryHandler{categories: categories}
}

func (h *CategoryHandler) Register(r gin.IRouter) {
	r.GET("/categories", h.findAll)
}

func (h *CategoryHandler) findAll(c *gin.Context) {
	categories, err := h.categories.FindAll(c.Request.Context())
	if err != nil {
		_ = c.Error(err)
		return
	}
	c.JSON(http.StatusOK, toCategoryResponses(categories))
}
