// Package repository is the persistence layer: GORM queries behind small, typed methods.
package repository

import (
	"errors"
	"log/slog"
	"time"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// ErrNotFound is returned instead of gorm.ErrRecordNotFound so callers don't import GORM.
var ErrNotFound = errors.New("record not found")

func Open(path string, log *slog.Logger) (*gorm.DB, error) {
	return gorm.Open(sqlite.Open(path), &gorm.Config{
		Logger: logger.NewSlogLogger(log, logger.Config{
			SlowThreshold:             time.Second,
			LogLevel:                  logger.Warn,
			IgnoreRecordNotFoundError: true,
		}),
	})
}

func translate(err error) error {
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return ErrNotFound
	}
	return err
}
