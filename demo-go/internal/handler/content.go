package handler

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"

	"demo-go/internal/model"
)

type ContentService interface {
	FindPage(ctx context.Context, page, size int) ([]model.Content, error)
	FindByID(ctx context.Context, id int) (*model.Content, error)
	UpdateText(ctx context.Context, id int, text string) (*model.Content, error)
}

type ContentHandler struct {
	contents ContentService
}

func NewContentHandler(contents ContentService) *ContentHandler {
	return &ContentHandler{contents: contents}
}

func (h *ContentHandler) Register(r gin.IRouter) {
	g := r.Group("/contents")
	g.GET("", h.findPage)
	g.GET("/:id", h.findByID)
	g.PUT("/:id", h.updateText)
}

func (h *ContentHandler) findPage(c *gin.Context) {
	var q pageQuery
	if err := c.ShouldBindQuery(&q); err != nil {
		_ = c.Error(err).SetType(gin.ErrorTypeBind)
		return
	}
	contents, err := h.contents.FindPage(c.Request.Context(), q.Page, q.Size)
	if err != nil {
		_ = c.Error(err)
		return
	}
	c.JSON(http.StatusOK, contentPageResponse{
		Page:     q.Page,
		Size:     q.Size,
		Contents: toContentResponses(contents),
	})
}

func (h *ContentHandler) findByID(c *gin.Context) {
	var uri idURI
	if err := c.ShouldBindUri(&uri); err != nil {
		_ = c.Error(err).SetType(gin.ErrorTypeBind)
		return
	}
	content, err := h.contents.FindByID(c.Request.Context(), uri.ID)
	if err != nil {
		_ = c.Error(err)
		return
	}
	c.JSON(http.StatusOK, toContentResponse(content))
}

func (h *ContentHandler) updateText(c *gin.Context) {
	var uri idURI
	if err := c.ShouldBindUri(&uri); err != nil {
		_ = c.Error(err).SetType(gin.ErrorTypeBind)
		return
	}
	var body updateContentRequest
	if err := c.ShouldBindJSON(&body); err != nil {
		_ = c.Error(err).SetType(gin.ErrorTypeBind)
		return
	}
	content, err := h.contents.UpdateText(c.Request.Context(), uri.ID, body.Content)
	if err != nil {
		_ = c.Error(err)
		return
	}
	c.JSON(http.StatusOK, toContentResponse(content))
}
