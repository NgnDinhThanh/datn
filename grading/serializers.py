from rest_framework import serializers


class GradeSerializer(serializers.Serializer):
    id = serializers.CharField(read_only=True)
    class_code = serializers.CharField()
    exam_id = serializers.CharField()
    student_id = serializers.CharField()
    score = serializers.FloatField()
    answers = serializers.DictField()