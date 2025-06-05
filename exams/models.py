from mongoengine import Document, StringField, DictField, ListField


# Create your models here.
class Exam(Document):
    name = StringField(required=True)
    template_id = StringField(required=True)
    class_code = StringField(required=True)
    answer_keys = DictField()
    exam_codes = ListField(StringField())
