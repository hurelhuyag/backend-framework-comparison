<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ContentController;
use App\Http\Controllers\CategoryController;

Route::get('/contents', [ContentController::class, 'index']);
Route::get('/contents/{id}', [ContentController::class, 'show']);
Route::get('/categories', [CategoryController::class, 'index']);
Route::get('/hello', function() {
	return "Hello Laravel";
});
