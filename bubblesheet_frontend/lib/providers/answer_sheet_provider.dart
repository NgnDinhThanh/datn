import 'package:bubblesheet_frontend/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/answer_sheet_model.dart';
import '../services/answer_sheet_service.dart';

class AnswerSheetProvider extends ChangeNotifier {
  List<AnswerSheet> _answerSheets = [];
  bool _isLoading = false;
  String? _error;

  List<AnswerSheet> get answerSheets => _answerSheets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAnswerSheets(BuildContext context) async {
    print('Starting to fetch answer sheets...');
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      print('Token: ${token != null ? 'Present' : 'Missing'}');
      _answerSheets = await AnswerSheetService.getAnswerSheets(token);
      print('Fetched ${_answerSheets.length} answer sheets');
      for (var sheet in _answerSheets) {
        print('Sheet: ${sheet.name} (${sheet.id})');
      }
    } catch (e) {
      print('Error fetching answer sheets: $e');
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createAnswerSheet(BuildContext context, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      await AnswerSheetService.createAnswerSheet(data, token);
      await fetchAnswerSheets(context); // Refresh list after creating
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAnswerSheet(BuildContext context, String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      await AnswerSheetService.deleteAnswerSheet(id, token);
      await fetchAnswerSheets(context); // Reload list
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// Thêm các hàm create, delete, ... nếu cần
}
