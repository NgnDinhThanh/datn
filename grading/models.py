from mongoengine import Document, StringField, FloatField, DictField


# Create your models here.
class Grade(Document):
    class_code = StringField(required=True)
    exam_id = StringField(required=True)
    student_id = StringField(required=True)
    score = FloatField()
    answers = DictField()