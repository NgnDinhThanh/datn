import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/auth_provider.dart';
import 'package:bubblesheet_frontend/services/api_service.dart';
import '../models/answer_key_model.dart';
import 'dart:typed_data';
import 'dart:html' as html;

class AnswerKeyService {
  static Future<Map<String, dynamic>> generateAnswerKeys({
    required BuildContext context,
    required String quizId,
    required int numVersions,
    required PlatformFile answerFile,
  }) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final uri = Uri.parse('${ApiService.baseUrl}/answer-keys/generate/');
    final request = http.MultipartRequest('POST', uri)
      ..fields['quiz_id'] = quizId
      ..fields['num_versions'] = numVersions.toString()
      ..headers['Authorization'] = 'Bearer $token';

    request.files.add(
      http.MultipartFile.fromBytes(
        'answer_file',
        answerFile.bytes!,
        filename: answerFile.name,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'data': json.decode(response.body),
      };
    } else {
      return {
        'success': false,
        'error': response.body,
      };
    }
  }

  static Future<List<AnswerKeyModel>> getAnswerKeys({
    required BuildContext context,
    required String quizId,
  }) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final uri = Uri.parse('${ApiService.baseUrl}/answer-keys/quiz/$quizId/');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('API response: $data');
      return (data as List).map((e) => AnswerKeyModel.fromJson(e)).toList();
    } else {
      print('API error: ${response.body}');
      throw Exception('Failed to load answer keys');
    }
  }

  static Future<void> downloadAllAnswerKeysExcel(BuildContext context, String quizId) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final url = '${ApiService.baseUrl}/answer-keys/quiz/$quizId/download/';
    final response = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final content = response.bodyBytes;
      final blob = html.Blob([content]);
      final url2 = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url2)
        ..setAttribute('download', 'answer_keys_$quizId.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url2);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: ${response.statusCode}')),
      );
    }
  }
} 