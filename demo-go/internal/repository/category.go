package repository

import (
	"context"

	"gorm.io/gorm"

	"demo-go/internal/model"
)

type CategoryRepository struct {
	db *gorm.DB
}

func NewCategoryRepository(db *gorm.DB) *CategoryRepository {
	return &CategoryRepository{db: db}
}

func (r *CategoryRepository) FindAll(ctx context.Context) ([]model.Category, error) {
	var categories []model.Category
	err := r.db.WithContext(ctx).
		Preload("Parent.Parent").
		Order("id").
		Find(&categories).Error
	return categories, err
}
