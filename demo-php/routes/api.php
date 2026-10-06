<?php

use App\Http\Controllers\CategoryController;
use App\Http\Controllers\ContentController;
use Illuminate\Support\Facades\Route;

Route::get('/contents', [ContentController::class, 'index']);
Route::get('/contents/{id}', [ContentController::class, 'show'])->whereNumber('id');
Route::put('/contents/{id}', [ContentController::class, 'update'])->whereNumber('id');
Route::get('/categories', [CategoryController::class, 'index']);
