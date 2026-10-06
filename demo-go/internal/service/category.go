package service

import (
	"context"

	"demo-go/internal/model"
)

type CategoryRepository interface {
	FindAll(ctx context.Context) ([]model.Category, error)
}

type CategoryService struct {
	categories CategoryRepository
}

func NewCategoryService(categories CategoryRepository) *CategoryService {
	return &CategoryService{categories: categories}
}

func (s *CategoryService) FindAll(ctx context.Context) ([]model.Category, error) {
	return s.categories.FindAll(ctx)
}
