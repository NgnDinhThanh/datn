from django.urls import path

from grading.views import GradeListView, GradeDetailView

urlpatterns = [
    path('', GradeListView.as_view(), name='grade-list-create'),
    path('<str:id>/', GradeDetailView.as_view(), name='grade-detail' ),
]