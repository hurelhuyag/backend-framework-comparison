<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\BadRequestHttpException;

/**
 * Laravel silently treats an unparseable JSON body as an empty one. Reject it with 400 instead,
 * so a broken client is told its body is broken rather than that a field is missing.
 */
class RejectMalformedJson
{
    public function handle(Request $request, Closure $next): Response
    {
        if ($request->isJson() && $request->getContent() !== '') {
            json_decode($request->getContent());
            if (json_last_error() !== JSON_ERROR_NONE) {
                throw new BadRequestHttpException('Malformed JSON body.');
            }
        }

        return $next($request);
    }
}
