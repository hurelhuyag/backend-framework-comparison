// Package config loads runtime settings from the environment (12-factor style).
package config

import (
	"log/slog"
	"time"

	"github.com/caarlos0/env/v11"
)

type Config struct {
	Port            string        `env:"PORT" envDefault:"8080"`
	DatabaseURL     string        `env:"DATABASE_URL" envDefault:"postgres://bench:bench@127.0.0.1:5432/demo"`
	DBPoolSize      int           `env:"DB_POOL_SIZE" envDefault:"32"`
	LogLevel        slog.Level    `env:"LOG_LEVEL" envDefault:"WARN"`
	ShutdownTimeout time.Duration `env:"SHUTDOWN_TIMEOUT" envDefault:"10s"`
}

func Load() (Config, error) {
	return env.ParseAs[Config]()
}
