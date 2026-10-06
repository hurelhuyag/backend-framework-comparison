from django.shortcuts import render

from rest_framework import viewsets, mixins
from rest_framework.pagination import PageNumberPagination
from .models import Category, Content
from .serializers import CategorySerializer, ContentSerializer

from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response

class NoCountPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    page_query_param = 'page'
    max_page_size = 100

    def paginate_queryset(self, queryset, request, view=None):
        self.request = request
        self.page_size = self.get_page_size(request)
        if not self.page_size:
            return None

        try:
            page_number = int(request.query_params.get(self.page_query_param, 1))
            if page_number < 1:
                page_number = 1
        except ValueError:
            page_number = 1

        offset = (page_number - 1) * self.page_size
        # Important: slice the queryset but do NOT convert to list here
        self.page = queryset[offset:offset + self.page_size]
        self.current_page = page_number
        return self.page

    def get_paginated_response(self, data):
        # data here is already serialized by DRF
        return Response({
            'page': self.current_page,
            'page_size': self.page_size,
            'results': data
        })

class StandardResultsSetPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 100


class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer


# ReadOnlyModelViewSet plus UpdateModelMixin: adds PUT/PATCH without exposing create/destroy.
class ContentViewSet(mixins.UpdateModelMixin, viewsets.ReadOnlyModelViewSet):
    queryset = Content.objects.select_related('category').all()
    serializer_class = ContentSerializer
    # pagination_class = StandardResultsSetPagination
    pagination_class = NoCountPagination
