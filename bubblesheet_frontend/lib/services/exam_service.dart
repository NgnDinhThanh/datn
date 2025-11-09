import 'dart:convert';

import 'package:bubblesheet_frontend/models/exam_model.dart';
import 'package:bubblesheet_frontend/services/api_service.dart';
import 'package:bubblesheet_frontend/services/auth_helper.dart';
import 'package:http/http.dart' as http;
class ExamService {
  static Future<List<ExamModel>> getExams(String? token) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/exams/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    checkAuthError(response.statusCode, response.body);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ExamModel.fromJson(json)).toList();
    }
    throw Exception('Failed to load exams: Status ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> createExam(Map<String, dynamic> examData, String? token) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/exams/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(examData),
    );
    checkAuthError(response.statusCode, response.body);
    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to create exam: Status ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> updateExam(String examId, Map<String, dynamic> examData, String? token) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/exams/$examId/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(examData),
    );
    checkAuthError(response.statusCode, response.body);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to update exam: Status ${response.statusCode}');
  }

  static Future<void> deleteExam(String examId, String? token) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/exams/$examId/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    checkAuthError(response.statusCode, response.body);
    if (response.statusCode != 204) {
      throw Exception('Failed to delete exam: Status ${response.statusCode}');
    }
  }

  static Future<ExamModel> getExamDetail(String examId, String? token) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/exams/$examId/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    checkAuthError(response.statusCode, response.body);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return ExamModel.fromJson(data);
    }
    throw Exception('Failed to fetch exam detail: Status ${response.statusCode}');
  }
}