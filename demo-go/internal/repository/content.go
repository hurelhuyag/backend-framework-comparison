package repository

import (
	"context"

	"gorm.io/gorm"

	"demo-go/internal/model"
)

type ContentRepository struct {
	db *gorm.DB
}

func NewContentRepository(db *gorm.DB) *ContentRepository {
	return &ContentRepository{db: db}
}

// withCategory loads content -> category -> parent. Preload issues one batched IN query
// per level, so a page costs three statements and no COUNT(*).
func (r *ContentRepository) withCategory(ctx context.Context) *gorm.DB {
	return r.db.WithContext(ctx).Preload("Category").Preload("Category.Parent")
}

func (r *ContentRepository) FindPage(ctx context.Context, offset, limit int) ([]model.Content, error) {
	var contents []model.Content
	err := r.withCategory(ctx).
		Order("id").
		Offset(offset).
		Limit(limit).
		Find(&contents).Error
	return contents, err
}

func (r *ContentRepository) FindByID(ctx context.Context, id int) (*model.Content, error) {
	var content model.Content
	if err := r.withCategory(ctx).First(&content, id).Error; err != nil {
		return nil, translate(err)
	}
	return &content, nil
}

// UpdateText rewrites only the text column and returns the row without its category.
func (r *ContentRepository) UpdateText(ctx context.Context, id int, text string) (*model.Content, error) {
	var content model.Content
	db := r.db.WithContext(ctx)
	if err := db.First(&content, id).Error; err != nil {
		return nil, translate(err)
	}
	if err := db.Model(&content).Update("content", text).Error; err != nil {
		return nil, err
	}
	return &content, nil
}
