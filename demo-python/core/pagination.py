from rest_framework import serializers
from rest_framework.pagination import BasePagination
from rest_framework.response import Response


class PageQuerySerializer(serializers.Serializer):
    """Validates the paging query parameters; bad values become a 400 response."""

    page = serializers.IntegerField(min_value=1, default=1)
    page_size = serializers.IntegerField(min_value=1, max_value=100, default=20)


class NoCountPagination(BasePagination):
    """Page/page_size pagination without a COUNT query.

    The response carries only page, page_size and results; a page past the end is an
    empty result list rather than a 404, because detecting it would need a count.
    """

    def paginate_queryset(self, queryset, request, view=None):
        params = PageQuerySerializer(data=request.query_params)
        params.is_valid(raise_exception=True)
        self.page = params.validated_data['page']
        self.page_size = params.validated_data['page_size']
        offset = (self.page - 1) * self.page_size
        # Slicing keeps it lazy: the serializer runs one LIMIT/OFFSET query.
        return queryset[offset : offset + self.page_size]

    def get_paginated_response(self, data):
        return Response(
            {
                'page': self.page,
                'page_size': self.page_size,
                'results': data,
            }
        )
