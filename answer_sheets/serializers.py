from rest_framework import serializers


class AnswerSheetTemplateSerializer(serializers.Serializer):
    id = serializers.CharField(read_only=True)
    name = serializers.CharField()
    headers = serializers.ListField(child=serializers.DictField())
    num_questions = serializers.IntegerField()
    num_choices = serializers.IntegerField()
    student_id_digits = serializers.IntegerField()
    exam_id_digits = serializers.IntegerField()
    class_id_digits = serializers.IntegerField()
    preview_image = serializers.CharField()
    owner = serializers.CharField()