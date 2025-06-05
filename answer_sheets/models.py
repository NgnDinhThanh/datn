from mongoengine import Document, StringField, ListField, DictField, IntField


# Create your models here.
class AnswerSheetTemplate(Document):
    name = StringField(required=True)
    headers = ListField(DictField())
    num_questions = IntField()
    num_choices = IntField()
    student_id_digits = IntField()
    exam_id_digits = IntField()
    class_id_digits = IntField()
    preview_image = StringField()
    owner = StringField()
