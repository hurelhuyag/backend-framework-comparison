package service

import (
	"context"
	"errors"
	"fmt"

	"demo-go/internal/model"
	"demo-go/internal/repository"
)

type ContentRepository interface {
	FindPage(ctx context.Context, offset, limit int) ([]model.Content, error)
	FindByID(ctx context.Context, id int) (*model.Content, error)
	UpdateText(ctx context.Context, id int, text string) (*model.Content, error)
}

type ContentService struct {
	contents ContentRepository
}

func NewContentService(contents ContentRepository) *ContentService {
	return &ContentService{contents: contents}
}

// FindPage takes a 1-based page number; page and size are already validated by the handler.
func (s *ContentService) FindPage(ctx context.Context, page, size int) ([]model.Content, error) {
	contents, err := s.contents.FindPage(ctx, (page-1)*size, size)
	if err != nil {
		return nil, fmt.Errorf("find content page %d: %w", page, err)
	}
	return contents, nil
}

func (s *ContentService) FindByID(ctx context.Context, id int) (*model.Content, error) {
	content, err := s.contents.FindByID(ctx, id)
	return content, s.wrap(err, "find content %d", id)
}

// UpdateText rewrites only the text, so the row count never changes and reads stay comparable.
func (s *ContentService) UpdateText(ctx context.Context, id int, text string) (*model.Content, error) {
	content, err := s.contents.UpdateText(ctx, id, text)
	return content, s.wrap(err, "update content %d", id)
}

func (s *ContentService) wrap(err error, format string, args ...any) error {
	switch {
	case err == nil:
		return nil
	case errors.Is(err, repository.ErrNotFound):
		return ErrContentNotFound
	default:
		return fmt.Errorf(format+": %w", append(args, err)...)
	}
}
