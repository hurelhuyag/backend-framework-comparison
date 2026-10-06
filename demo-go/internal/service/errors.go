// Package service is the business layer. It depends on repository interfaces it declares
// itself, so tests can swap in fakes without touching GORM.
package service

import "errors"

var ErrContentNotFound = errors.New("content not found")
