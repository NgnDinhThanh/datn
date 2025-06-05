from django.urls import path

from answer_sheets.views import AnswerSheetTemplateListCreateView, AnswerSheetTemplateDetailView

urlpatterns = [
    path('', AnswerSheetTemplateListCreateView.as_view(), name='answersheet-list-create'),
    path('<str:id>/', AnswerSheetTemplateDetailView.as_view(), name='answersheet-detail' ),
]