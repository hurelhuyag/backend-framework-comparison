<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ListContentsRequest extends FormRequest
{
    public const DEFAULT_PAGE_SIZE = 10;

    /**
     * @return array<string, list<string>>
     */
    public function rules(): array
    {
        return [
            'page' => ['sometimes', 'integer', 'min:1'],
            'page_size' => ['sometimes', 'integer', 'min:1', 'max:100'],
        ];
    }

    public function page(): int
    {
        return (int) $this->validated('page', 1);
    }

    public function pageSize(): int
    {
        return (int) $this->validated('page_size', self::DEFAULT_PAGE_SIZE);
    }
}
