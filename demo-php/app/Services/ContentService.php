<?php

namespace App\Services;

use App\Models\Content;
use Illuminate\Database\Eloquent\Collection;

class ContentService
{
    /**
     * Categories are at most 3 levels deep. The last hop always finds parent_id null, so Eloquent
     * sets `parent` to null without running a query; every level is one batched query, no N+1.
     */
    private const CATEGORY_CHAIN = 'category.parent.parent.parent';

    /**
     * @return Collection<int, Content>
     */
    public function paginate(int $page, int $pageSize): Collection
    {
        return Content::with(self::CATEGORY_CHAIN)
            ->orderBy('id')
            ->skip(($page - 1) * $pageSize)
            ->take($pageSize)
            ->get();
    }

    public function find(int $id): Content
    {
        return Content::with(self::CATEGORY_CHAIN)->findOrFail($id);
    }

    // Rewrites only the text, so the row count never changes and reads stay comparable.
    public function updateText(int $id, string $text): Content
    {
        $content = Content::findOrFail($id);
        $content->content = $text;
        $content->save();

        return $content;
    }
}
