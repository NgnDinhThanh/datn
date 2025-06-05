from mongoengine import Document, StringField, IntField, ListField, ValidationError, ObjectIdField

from users.models import User
import re
from bson import ObjectId


# Create your models here.
class Class(Document):
    class_code = StringField(required=True, unique=True, max_length=20)
    class_name = StringField(required=True, max_length=100)
    student_count = IntField(default=0)
    teacher_id = ObjectIdField(required=True)
    student_ids = ListField(ObjectIdField())

    meta = {
        'collection': 'classes',
        'indexes': ['class_code', 'teacher_id']
    }

    def clean(self):
        from students.models import Student  # Import động để tránh circular import
        # Validate class_code format
        if not re.match(r'^[A-Za-z0-9]+$', self.class_code):
            raise ValidationError('Class code must contain only alphanumeric characters')

        # Validate student_ids
        if self.student_ids:
            for student_id in self.student_ids:
                if not isinstance(student_id, ObjectId):
                    raise ValidationError('Student ID must be a valid ObjectId')
        
        # Validate teacher exists
        teacher = User.objects(id=self.teacher_id, is_teacher=True).first()
        if not teacher:
            raise ValidationError("Teacher not found or is not a teacher")
        
        # Validate student_ids if provided
        if self.student_ids:
            for student_id in self.student_ids:
                student = Student.objects(id=student_id).first()
                if not student:
                    raise ValidationError(f"Student with id {student_id} not found")
        
        # Update student_count
        self.student_count = len(self.student_ids)