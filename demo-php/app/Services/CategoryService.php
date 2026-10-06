<?php

namespace App\Services;

use App\Models\Category;
use Illuminate\Database\Eloquent\Collection;

class CategoryService
{
    /**
     * All categories with their full parent chain (at most 3 levels; the last hop costs no query).
     *
     * @return Collection<int, Category>
     */
    public function all(): Collection
    {
        return Category::with('parent.parent.parent')->orderBy('id')->get();
    }
}
