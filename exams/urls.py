from django.urls import path

from exams.views import ExamListCreateView, ExamDetailView

urlpatterns = [
    path('', ExamListCreateView.as_view(), name='exam-list-create'),
    path('<str:id>/', ExamDetailView.as_view(), name='exam-detail' ),
]