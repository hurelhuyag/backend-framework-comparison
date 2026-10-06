from rest_framework import serializers
from .models import Category, Content


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'parent', 'name']


class CategoryWithParentSerializer(serializers.ModelSerializer):
    parent = serializers.SerializerMethodField()

    class Meta:
        model = Category
        fields = ['id', 'name', 'parent']

    def get_parent(self, obj):
        # Recurses up to the root. The view eager-loads the chain with select_related,
        # so no extra queries are issued; checking parent_id avoids touching a null FK.
        if obj.parent_id is None:
            return None
        return CategoryWithParentSerializer(obj.parent).data


class ContentSerializer(serializers.ModelSerializer):
    category = CategoryWithParentSerializer(read_only=True)

    class Meta:
        model = Content
        fields = ['id', 'category', 'content']
        # The column is unbounded TEXT; the API caps updates like the other demos do.
        extra_kwargs = {'content': {'max_length': 1000}}
