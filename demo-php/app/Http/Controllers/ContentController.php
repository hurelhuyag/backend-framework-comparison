<?php

namespace App\Http\Controllers;

use App\Http\Requests\ListContentsRequest;
use App\Http\Requests\UpdateContentRequest;
use App\Http\Resources\ContentResource;
use App\Services\ContentService;
use Illuminate\Http\JsonResponse;

class ContentController extends Controller
{
    public function __construct(private readonly ContentService $contents)
    {
    }

    public function index(ListContentsRequest $request): JsonResponse
    {
        $page = $request->page();
        $pageSize = $request->pageSize();

        return response()->json([
            'page' => $page,
            'page_size' => $pageSize,
            'data' => ContentResource::collection($this->contents->paginate($page, $pageSize)),
        ]);
    }

    public function show(int $id): ContentResource
    {
        return new ContentResource($this->contents->find($id));
    }

    public function update(UpdateContentRequest $request, int $id): ContentResource
    {
        return new ContentResource($this->contents->updateText($id, $request->text()));
    }
}
