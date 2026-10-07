// Package repository is the persistence layer: GORM queries behind small, typed methods.
package repository

import (
	"errors"
	"log/slog"
	"time"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// ErrNotFound is returned instead of gorm.ErrRecordNotFound so callers don't import GORM.
var ErrNotFound = errors.New("record not found")

// Open connects to PostgreSQL through the pgx database/sql driver. dsn is a libpq URL or
// key=value string; anything it leaves out falls back to the PG* environment variables.
// The database/sql pool is capped at poolSize, and idle connections are kept up to the same
// number so they are reused under load instead of being closed and reopened.
func Open(dsn string, poolSize int, log *slog.Logger) (*gorm.DB, error) {
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.NewSlogLogger(log, logger.Config{
			SlowThreshold:             time.Second,
			LogLevel:                  logger.Warn,
			IgnoreRecordNotFoundError: true,
		}),
	})
	if err != nil {
		return nil, err
	}
	sqlDB, err := db.DB()
	if err != nil {
		return nil, err
	}
	sqlDB.SetMaxOpenConns(poolSize)
	sqlDB.SetMaxIdleConns(poolSize)
	return db, nil
}

func translate(err error) error {
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return ErrNotFound
	}
	return err
}
