package main

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/mux"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

type Category struct {
	Id       int        `gorm:"primaryKey" json:"id"`
	ParentId *int       `gorm:"column:parent_id" json:"parent_id"`
	Parent   *Category  `gorm:"foreignKey:ParentId;references:Id" json:"parent"`
	Name     string     `gorm:"not null" json:"name"`
	Children []Category `gorm:"foreignKey:ParentId" json:"children"`
}

func (Category) TableName() string {
	return "category"
}

type Content struct {
	Id         int       `gorm:"primaryKey" json:"id"`
	CategoryId *int      `gorm:"column:category_id" json:"category_id"`
	Category   *Category `gorm:"foreignKey:CategoryId;references:Id" json:"category"`
	Content    string    `gorm:"not null" json:"content"`
}

func (Content) TableName() string {
	return "content"
}

var db *gorm.DB

func main() {
	newLogger := logger.New(
		log.New(log.Writer(), "\r\n", log.LstdFlags), // io writer
		logger.Config{
			SlowThreshold: time.Second,  // slow SQL threshold
			LogLevel:      logger.Error, // log level
			Colorful:      true,
		},
	)

	var err error
	db, err = gorm.Open(sqlite.Open("demo.sqlite"), &gorm.Config{
		Logger: newLogger,
	})
	if err != nil {
		log.Fatal(err)
	}

	r := mux.NewRouter()
	r.HandleFunc("/categories", GetCategories).Methods("GET")
	r.HandleFunc("/contents", GetContents).Methods("GET")
	r.HandleFunc("/contents/{id:[0-9]+}", GetContent).Methods("GET")

	log.Println("Server started at :8080")
	log.Fatal(http.ListenAndServe(":8080", r))
}

func GetCategories(w http.ResponseWriter, r *http.Request) {
	var categories []Category
	db.Model(&Category{}).Preload("Parent").Find(&categories)
	json.NewEncoder(w).Encode(categories)
}

func GetContents(w http.ResponseWriter, r *http.Request) {
	pageParam := r.URL.Query().Get("page")
	sizeParam := r.URL.Query().Get("size")

	page := 1
	size := 10

	if pageParam != "" {
		if p, err := strconv.Atoi(pageParam); err == nil && p > 0 {
			page = p
		}
	}

	if sizeParam != "" {
		if s, err := strconv.Atoi(sizeParam); err == nil && s > 0 {
			size = s
		}
	}

	var contents []Content
	var total int64
	//db.Model(&Content{}).Count(&total)
	db.Offset((page - 1) * size).Preload("Category").Preload("Category.Parent").Limit(size).Find(&contents)

	response := map[string]interface{}{
		"page":     page,
		"size":     size,
		"total":    total,
		"contents": contents,
	}

	w.Header().Set("content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func GetContent(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(mux.Vars(r)["id"])
	var content Content
	if db.Model(content).Preload("Category").Preload("Category.Parent").First(&content, id).Error != nil {
		http.Error(w, "content not found", 404)
		return
	}
	json.NewEncoder(w).Encode(content)
}
