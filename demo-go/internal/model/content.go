package model

type Content struct {
	ID         int       `gorm:"column:id;primaryKey"`
	CategoryID *int      `gorm:"column:category_id"`
	Category   *Category `gorm:"foreignKey:CategoryID;references:ID"`
	Content    string    `gorm:"column:content;not null"`
}

func (Content) TableName() string {
	return "content"
}
