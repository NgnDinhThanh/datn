from bson import ObjectId
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
import logging

from classes.models import Class
from students.models import Student
from students.serializers import StudentSerializer

# Set up logging
logger = logging.getLogger(__name__)

# Create your views here.
class StudentListCreateView(APIView):
    permission_students = [IsAuthenticated]

    def get(self, request):
        try:
            # Log tất cả student trong database
            all_students = Student.objects.all()
            logger.info(f"All students in database: {[s.student_id for s in all_students]}")
            
            # Lấy danh sách student của teacher
            students = Student.objects.filter(teacher_id=request.user.id)
            serializer = StudentSerializer(students, many=True)
            return Response(serializer.data)
        except Exception as e:
            logger.error(f"Error getting students: {str(e)}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def post(self, request):
        try:
            serializer = StudentSerializer(data=request.data)
            if not serializer.is_valid():
                logger.warning(f"Invalid student data: {serializer.errors}")
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

            # Validate student_id format
            student_id = serializer.validated_data['student_id']
            if not student_id.isalnum():
                logger.warning(f"Invalid student_id format: {student_id}")
                return Response({
                    "error": "Student ID must contain only letters and numbers"
                }, status=status.HTTP_400_BAD_REQUEST)

            if Student.objects(student_id=student_id).first():
                logger.warning(f"Student with ID {student_id} already exists")
                return Response(
                    {"error": "Student with this student_id already exists"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Lấy danh sách class_codes nếu có
            class_codes = request.data.get('class_codes', [])
            valid_class_object_ids = []
            invalid_class_ids = []
            
            for class_code in class_codes:
                try:
                    # Tìm class bằng class_code
                    class_obj = Class.objects.get(class_code=str(class_code))
                    
                    # Kiểm tra xem class có thuộc về teacher không
                    if class_obj and class_obj.teacher_id == request.user.id:
                        valid_class_object_ids.append(class_obj.id)
                        logger.info(f"Found valid class: {class_obj.class_code}")
                    else:
                        invalid_class_ids.append(str(class_code))
                        logger.warning(f"Class {class_code} does not belong to teacher {request.user.id}")
                except Exception as e:
                    invalid_class_ids.append(str(class_code))
                    logger.error(f"Error finding class {class_code}: {str(e)}")

            # Create new student
            student_obj = Student(
                student_id=serializer.validated_data['student_id'],
                first_name=serializer.validated_data['first_name'],
                last_name=serializer.validated_data['last_name'],
                teacher_id=request.user.id,
                class_codes=valid_class_object_ids
            )
            student_obj.save()
            logger.info(f"Created new student {student_id} for teacher {request.user.id}")

            # Cập nhật chiều ngược lại: thêm student vào student_ids của từng class
            for class_id in valid_class_object_ids:
                try:
                    class_obj = Class.objects.get(id=class_id)
                    if student_obj.id not in class_obj.student_ids:
                        class_obj.student_ids.append(student_obj.id)
                        class_obj.student_count = len(class_obj.student_ids)
                        class_obj.save()
                        logger.info(f"Added student {student_id} to class {class_obj.class_code}")
                except Exception as e:
                    logger.error(f"Error updating class {class_id}: {str(e)}")
                    continue

            # Return response with invalid class IDs if any
            response_data = {
                'student_id': student_obj.student_id,
                'first_name': student_obj.first_name,
                'last_name': student_obj.last_name,
                'teacher_id': str(student_obj.teacher_id),
                'class_codes': [str(id) for id in student_obj.class_codes]
            }
            
            if invalid_class_ids:
                response_data['invalid_class_ids'] = invalid_class_ids
                response_data['message'] = f"Student created with {len(valid_class_object_ids)} classes. {len(invalid_class_ids)} invalid class codes were ignored."

            return Response(response_data, status=status.HTTP_201_CREATED)
        except Exception as e:
            logger.error(f"Error creating student: {str(e)}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class StudentDetailView(APIView):
    permission_students = [IsAuthenticated]
    def get_object(self, student_id):
        try:
            student = Student.objects.get(student_id=student_id)
            logger.debug(f"Found student {student_id}")
            return student
        except Student.DoesNotExist:
            logger.warning(f"Student {student_id} not found")
            return None
        except Exception as e:
            logger.error(f"Error retrieving student {student_id}: {str(e)}")
            return None

    def get(self, request, student_id):
        try:
            student_obj = self.get_object(student_id)
            if not student_obj:
                return Response(
                    {'error': 'Student not found'},
                    status=status.HTTP_404_NOT_FOUND
                )

            if not (request.user.is_teacher and request.user.id == student_obj.teacher_id):
                logger.warning(f"User {request.user.id} attempted to access student {student_id} without permission")
                return Response(
                    {"error": "You don't have permission to view this student"},
                    status=status.HTTP_403_FORBIDDEN
                )

            return Response({
                "student_id": student_obj.student_id,
                "first_name": student_obj.first_name,
                "last_name": student_obj.last_name,
                "teacher_id": str(student_obj.teacher_id),
                "class_codes": [str(id) for id in student_obj.class_codes]
            })
        except Exception as e:
            logger.error(f"Error retrieving student details: {str(e)}")
            return Response(
                {'error': "Failed to retrieve student details"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def put(self, request, student_id):
        try:
            logger.info(f"Attempting to find student with student_id: {student_id}")
            # Log tất cả student trong database
            all_students = Student.objects.all()
            logger.info(f"All students in database: {[s.student_id for s in all_students]}")
            
            # Thử tìm student bằng student_id
            try:
                student = Student.objects.get(student_id=student_id)
                logger.info(f"Found student: {student.student_id}")
            except Student.DoesNotExist:
                logger.error(f"Student with student_id {student_id} not found")
                return Response(
                    {"error": f"Student with ID {student_id} not found"},
                    status=status.HTTP_404_NOT_FOUND
                )
            except Exception as e:
                logger.error(f"Error finding student: {str(e)}")
                return Response(
                    {"error": str(e)},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )

            if student.teacher_id != request.user.id:
                logger.warning(f"User {request.user.id} attempted to update student {student_id} without permission")
                return Response(
                    {"error": "You don't have permission to update this student"},
                    status=status.HTTP_403_FORBIDDEN
                )

            # Lấy danh sách class_codes mới từ request
            new_class_codes = []
            invalid_class_codes = []
            for class_code in request.data.get('class_codes', []):
                try:
                    # Tìm class bằng class_code
                    class_obj = Class.objects.get(class_code=str(class_code))
                    if class_obj.teacher_id == request.user.id:  # Kiểm tra class có thuộc về teacher không
                        new_class_codes.append(class_obj.id)
                        logger.info(f"Found valid class: {class_obj.class_code}")
                    else:
                        invalid_class_codes.append(str(class_code))
                        logger.warning(f"Class {class_code} does not belong to teacher {request.user.id}")
                except Exception as e:
                    invalid_class_codes.append(str(class_code))
                    logger.error(f"Error finding class {class_code}: {str(e)}")

            old_class_codes = student.class_codes
            logger.info(f"Current class_codes: {old_class_codes}")

            # Chỉ thêm các class mới (chưa có trong old_class_codes)
            classes_to_add = set(new_class_codes) - set(old_class_codes)
            logger.info(f"Classes to add: {classes_to_add}")
            
            for class_id in classes_to_add:
                try:
                    class_obj = Class.objects.get(id=class_id)
                    if student.id not in class_obj.student_ids:
                        class_obj.student_ids.append(student.id)
                        class_obj.student_count = len(class_obj.student_ids)
                        class_obj.save()
                        logger.info(f"Added student {student.student_id} to class {class_obj.class_code}")
                except Exception as e:
                    logger.error(f"Error adding student to class {class_id}: {str(e)}")

            # Cập nhật thông tin student
            if 'first_name' in request.data:
                student.first_name = request.data['first_name']
            if 'last_name' in request.data:
                student.last_name = request.data['last_name']
            if 'class_codes' in request.data:
                # Giữ nguyên các class_codes cũ và thêm các class_codes mới
                student.class_codes = list(set(old_class_codes) | set(new_class_codes))
                logger.info(f"Updated class_codes: {student.class_codes}")
            
            student.save()
            logger.info(f"Updated student {student.student_id}")

            # Serialize để trả về response
            serializer = StudentSerializer(student)
            response_data = serializer.data
            
            # Thêm thông tin về các class_code không hợp lệ nếu có
            if invalid_class_codes:
                response_data['invalid_class_codes'] = invalid_class_codes
                response_data['message'] = f"Added {len(classes_to_add)} new classes. {len(invalid_class_codes)} invalid class codes were ignored."
            
            return Response(response_data)
        except Exception as e:
            logger.error(f"Error updating student: {str(e)}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    def delete(self, request, student_id):
        try:
            student_obj = self.get_object(student_id)
            if not student_obj:
                return Response(
                    {"error": "Student not found"},
                    status=status.HTTP_404_NOT_FOUND
                )

            if not (request.user.is_teacher and request.user.id == student_obj.teacher_id):
                logger.warning(f"User {request.user.id} attempted to delete student {student_id} without permission")
                return Response(
                    {"error": "Only the teacher can delete this student"},
                    status=status.HTTP_403_FORBIDDEN
                )

            # Remove student from all classes
            for class_id in student_obj.class_codes:
                try:
                    class_obj = Class.objects.get(id=class_id)
                    class_obj.remove_student(student_obj.id)
                    logger.debug(f"Removed student {student_id} from class {class_id}")
                except Class.DoesNotExist:
                    logger.warning(f"Class {class_id} not found when removing student {student_id}")

            student_obj.delete()
            logger.info(f"Deleted student {student_id}")
            return Response(status=status.HTTP_204_NO_CONTENT)
        except Exception as e:
            logger.error(f"Error deleting student {student_id}: {str(e)}")
            return Response(
                {'error': "Failed to delete student"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
