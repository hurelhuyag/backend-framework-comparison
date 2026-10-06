package handler

import "demo-go/internal/model"

// Request DTOs. `binding` tags are go-playground/validator rules, run by Gin on bind.

type pageQuery struct {
	Page int `form:"page,default=1" binding:"min=1"`
	Size int `form:"size,default=20" binding:"min=1,max=100"`
}

type idURI struct {
	ID int `uri:"id" binding:"required,min=1"`
}

type updateContentRequest struct {
	Content string `json:"content" binding:"required,max=1000"`
}

// Response DTOs. Keys are snake_case to match the other demos.

type categoryResponse struct {
	ID       int               `json:"id"`
	ParentID *int              `json:"parent_id"`
	Name     string            `json:"name"`
	Parent   *categoryResponse `json:"parent"`
}

type contentResponse struct {
	ID         int               `json:"id"`
	CategoryID *int              `json:"category_id"`
	Content    string            `json:"content"`
	Category   *categoryResponse `json:"category"`
}

type contentPageResponse struct {
	Page     int               `json:"page"`
	Size     int               `json:"size"`
	Contents []contentResponse `json:"contents"`
}

// Mappers. Hand-written rather than reflection-based, as is usual in Go codebases.

func toCategoryResponse(c *model.Category) *categoryResponse {
	if c == nil {
		return nil
	}
	return &categoryResponse{
		ID:       c.ID,
		ParentID: c.ParentID,
		Name:     c.Name,
		Parent:   toCategoryResponse(c.Parent),
	}
}

func toCategoryResponses(categories []model.Category) []categoryResponse {
	out := make([]categoryResponse, len(categories))
	for i := range categories {
		out[i] = *toCategoryResponse(&categories[i])
	}
	return out
}

func toContentResponse(c *model.Content) contentResponse {
	return contentResponse{
		ID:         c.ID,
		CategoryID: c.CategoryID,
		Content:    c.Content,
		Category:   toCategoryResponse(c.Category),
	}
}

func toContentResponses(contents []model.Content) []contentResponse {
	out := make([]contentResponse, len(contents))
	for i := range contents {
		out[i] = toContentResponse(&contents[i])
	}
	return out
}
