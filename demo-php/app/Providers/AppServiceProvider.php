<?php

namespace App\Providers;

use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        // Single resources are returned as the bare object, not wrapped in {"data": ...}.
        JsonResource::withoutWrapping();
    }
}
