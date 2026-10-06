from rest_framework import mixins, viewsets

from .models import Category, Content
from .pagination import NoCountPagination
from .serializers import CategorySerializer, ContentSerializer


class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Category.objects.order_by('id')
    serializer_class = CategorySerializer


# ReadOnlyModelViewSet plus UpdateModelMixin: adds PUT/PATCH without exposing create/destroy.
class ContentViewSet(mixins.UpdateModelMixin, viewsets.ReadOnlyModelViewSet):
    # Categories are at most 3 levels deep (content -> category -> parent -> root), so
    # three hops of select_related load the whole chain in the same single query.
    queryset = Content.objects.select_related('category__parent__parent').order_by('id')
    serializer_class = ContentSerializer
    pagination_class = NoCountPagination
