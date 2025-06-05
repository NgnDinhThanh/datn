from rest_framework import serializers


class ExamSerializer(serializers.Serializer):
    id = serializers.CharField(read_only=True)
    name = serializers.CharField()
    template_id = serializers.CharField()
    class_code = serializers.CharField()
    answer_keys = serializers.DictField()
    exam_codes = serializers.ListField(child=serializers.CharField())
