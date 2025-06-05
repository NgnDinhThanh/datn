# Create your views here.
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from answer_sheets.models import AnswerSheetTemplate
from answer_sheets.serializers import AnswerSheetTemplateSerializer


class AnswerSheetTemplateListCreateView(APIView):
    def get(self, request):
        templates = AnswerSheetTemplate.objects.all()
        serializer = AnswerSheetTemplateSerializer(templates, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = AnswerSheetTemplateSerializer(data=request.data)
        if serializer.is_valid():
            template_obj = AnswerSheetTemplate(**serializer.validated_data)
            template_obj.save()
            return Response(AnswerSheetTemplateSerializer(template_obj).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class AnswerSheetTemplateDetailView(APIView):
    def get_object(self, id):
        return AnswerSheetTemplate.objects(id=id).first()

    def get(self, request, id):
        template_obj = self.get_object(id)
        if not template_obj:
            return Response({'error': 'Not found'}, status=404)
        serializer = AnswerSheetTemplateSerializer(template_obj)
        return Response(serializer.data)

    def put(self, request, id):
        template_obj = self.get_object(id)
        if not template_obj:
            return Response({'error': 'Not found'}, status=404)
        serializer = AnswerSheetTemplateSerializer(template_obj, data=request.data)
        if serializer.is_valid():
            for attr, value in serializer.validated_data.items():
                setattr(template_obj, attr, value)
            template_obj.save()
            return Response(AnswerSheetTemplateSerializer(template_obj).data)
        return Response(serializer.errors, status=404)

    def delte(self, request, id):
        template_obj = self.get_object(id)
        if not template_obj:
            return Response({'error': 'Not found'}, status=404)
        template_obj.delete()
        return Response(status=204)