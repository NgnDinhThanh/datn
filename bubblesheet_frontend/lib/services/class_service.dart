import 'dart:convert';
import 'package:bubblesheet_frontend/models/class_model.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart'; // Để dùng baseUrl, globalToken

class ClassService {
  static Future<List<ClassModel>> getClasses(String? token) async {
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/classes/'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ClassModel.fromJson(json)).toList();
    }
    throw Exception('Failed to load classes');
  }

  static Future<Map<String, dynamic>> createClass(Map<String, dynamic> classData, String? token) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/classes/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(classData),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to create class');
  }

  static Future<Map<String, dynamic>> updateClass(String classId, Map<String, dynamic> classData, String? token) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/classes/$classId/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(classData),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to update class');
  }

  static Future<void> deleteClass(String classId, String? token) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/classes/$classId/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete class');
    }
  }

  static Future<ClassModel> getClassDetail(String classId, String? token) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/classes/$classId/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return ClassModel.fromJson(data);
    }
    throw Exception('Failed to fetch class detail');
  }
} 