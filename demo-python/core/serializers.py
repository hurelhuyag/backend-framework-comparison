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
        if obj.parent:
            return {'id': obj.parent.id, 'name': obj.parent.name}
        return None

class ContentSerializer(serializers.ModelSerializer):
    category = CategoryWithParentSerializer(read_only=True)

    class Meta:
        model = Content
        fields = ['id', 'category', 'content']
