import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _currentUser;
  String? _token;
  bool _isLoading = true;

  String? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    print('🔍 AuthProvider: Loading user from SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();
    _currentUser = prefs.getString('currentUser');
    _token = prefs.getString('token');
    print('🔍 AuthProvider: currentUser = $_currentUser');
    print('🔍 AuthProvider: token = ${_token != null ? "EXISTS" : "NULL"}');
    ApiService.setToken(_token);
    _isLoading = false;
    print('🔍 AuthProvider: isLoading = false, notifying listeners');
    notifyListeners();
  }

  Future<void> setCurrentUser(String user, String token) async {
    print('🔍 AuthProvider: Setting current user = $user');
    print('🔍 AuthProvider: Setting token = ${token != null ? "EXISTS" : "NULL"}');
    _currentUser = user;
    _token = token;
    ApiService.setToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUser', user);
    await prefs.setString('token', token);
    print('🔍 AuthProvider: User saved to SharedPreferences, notifying listeners');
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    ApiService.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUser');
    await prefs.remove('token');
    notifyListeners();
  }
}