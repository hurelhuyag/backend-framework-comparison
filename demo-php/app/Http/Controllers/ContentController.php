<?php

namespace App\Http\Controllers;

use App\Models\Content;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;


class ContentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $page = (int) $request->query('page', '1');
        $perPage = (int) $request->query('page_size', '10');

        // Eager load category to avoid N+1
        $contents = Content::with('category.parent')
            ->skip(($page - 1) * $perPage)
            ->take($perPage)
            ->get();

        return response()->json([
            'page' => $page,
            'page_size' => $perPage,
            'data' => $contents,
        ]);
    }

    public function show(int $id): JsonResponse
    {
        $content = Content::with('category.parent')->findOrFail($id);
        return response()->json($content);
    }

    // Rewrites only the text, so the row count never changes and reads stay comparable.
    public function update(Request $request, int $id): JsonResponse
    {
        $validated = $request->validate([
            'content' => ['required', 'string', 'max:1000'],
        ]);

        $content = Content::findOrFail($id);
        $content->content = $validated['content'];
        $content->save();

        return response()->json($content);
    }
}
