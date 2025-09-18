import 'dart:convert';
import 'package:bubblesheet_frontend/models/class_model.dart';
import 'package:bubblesheet_frontend/models/student_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../mobile/login_screen.dart';

class ApiService {
  static final String baseUrl = kIsWeb
      ? 'http://127.0.0.1:8000/api'
      : 'http://10.0.2.2:8000/api';
  
  static String? _token;
  static BuildContext? _context;

  static void setContext(BuildContext context) {
    _context = context;
  }

  static void setToken(String? token) {
    _token = token;
  }

  // Đăng nhập
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/users/login/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _processResponse(response);
  }

  // Đăng ký
  static Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final url = Uri.parse('$baseUrl/users/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );
    return _processResponse(response);
  }

  // Lấy danh sách sinh viên
  static Future<List<Student>> getStudents() async {
    final response = await http.get(
      Uri.parse('$baseUrl/students/'),
      headers: _getAuthHeaders(),
    );
    final handledResponse = await _handleResponse(response);
    if (handledResponse.statusCode == 200) {
      final List<dynamic> data = json.decode(handledResponse.body);
      return data.map((json) => Student.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load students');
    }
  }

  // Thêm mới sinh viên
  static Future<Map<String, dynamic>> addStudent(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/students/'),
      headers: _getAuthHeaders(),
      body: jsonEncode(data),
    );
    final handledResponse = await _handleResponse(response);
    return _processResponse(handledResponse);
  }

  // Hàm lấy headers có token
  static Map<String, String> _getAuthHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Xử lý response chung
  static Map<String, dynamic> _processResponse(http.Response response) {
    final Map<String, dynamic> result = {};
    result['statusCode'] = response.statusCode;
    try {
      result['body'] = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      result['body'] = response.body;
    }
    return result;
  }

  // Xử lý response và kiểm tra token hết hạn
  static Future<http.Response> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      // Token hết hạn, logout và chuyển về màn hình login
      if (_context != null) {
        await Provider.of<AuthProvider>(_context!, listen: false).logout();
        if (_context!.mounted) {
          Navigator.of(_context!).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    }
    return response;
  }
}