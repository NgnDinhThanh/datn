# Create your views here.
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from grading.models import Grade
from grading.serializers import GradeSerializer


class GradeListView(APIView):
    def get(self, request):
        gradebooks = Grade.objects.all()
        serializer = GradeSerializer(gradebooks, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = GradeSerializer(data=request.data)
        if serializer.is_valid():
            grade_obj = Grade(**serializer.validated_data)
            grade_obj.save()
            return Response(GradeSerializer(grade_obj).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class GradeDetailView(APIView):
    def get_object(self, id):
        return Grade.objects(id=id).first()

    def get(self, request, id):
        grade_obj = self.get_object(id)
        if not grade_obj:
            return Response({'error': 'Not found'}, status=404)
        serializer = GradeSerializer(grade_obj)
        return Response(serializer.data)

    def put(self, request, id):
        grade_obj = self.get_object(id)
        if not grade_obj:
            return Response({'error': 'Not found'}, status=404)
        serializer = GradeSerializer(grade_obj, data=request.data)
        if serializer.is_valid():
            for attr, value in serializer.validated_data.items():
                setattr(grade_obj, attr, value)
            grade_obj.save()
            return Response(GradeSerializer(grade_obj).data)
        return Response(serializer.errors, status=400)

    def delete(self, request, id):
        grade_obj = self.get_object(id)
        if not grade_obj:
            return Response({'error': 'Not found'}, status=404)
        grade_obj.delete()
        return Response(status=204)
