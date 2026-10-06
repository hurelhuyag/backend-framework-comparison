// Package model holds the GORM persistence entities. They never leave the service layer
// as-is: handlers map them to DTOs.
package model

type Category struct {
	ID       int       `gorm:"column:id;primaryKey"`
	ParentID *int      `gorm:"column:parent_id"`
	Parent   *Category `gorm:"foreignKey:ParentID;references:ID"`
	Name     string    `gorm:"column:name;not null"`
}

func (Category) TableName() string {
	return "category"
}
