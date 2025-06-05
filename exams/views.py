# Create your views here.
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from exams.models import Exam
from exams.serializers import ExamSerializer


class ExamListCreateView(APIView):
    def get(self, request):
        exams = Exam.objects.all()
        serializer = ExamSerializer(exams, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = ExamSerializer(data=request.data)
        if serializer.is_valid():
            exam_obj = Exam(**serializer.validated_data)
            exam_obj.save()
            return Response(ExamSerializer(exam_obj).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class ExamDetailView(APIView):
    def get_object(self, exam_id):
        return Exam.objects(exam_id=exam_id).first()

    def get(self, request, exam_id):
        exam_obj = self.get_object(exam_id)
        if not exam_obj:
            return Response({'error': 'Not found'}, status=404)
        serializer = ExamSerializer(exam_obj)
        return Response(serializer.data)

    def put(self, request, exam_id):
        exam_obj = self.get_object(exam_id)
        if not exam_obj:
            return Response({'error': 'Not found'}, status=404)
        serializer = ExamSerializer(exam_obj, data=request.data)
        if serializer.is_valid():
            for attr, value in serializer.validated_data.items():
                setattr(exam_obj, attr, value)
            exam_obj.save()
            return Response(ExamSerializer(exam_obj).data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, exam_id):
        exam_obj = self.get_object(exam_id)
        if not exam_obj:
            return Response({'error': 'Not found'}, status=404)
        exam_obj.delete()
        return Response(status=204)