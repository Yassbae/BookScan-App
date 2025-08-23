import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  late AuthService _authService;

  // Add this for tests ONLY
  @visibleForTesting
  void setAuthService(AuthService service) {
    _authService = service;
  }

  AuthViewModel() {
    final dio = Dio();
    _authService = AuthService(dio);
  }

  bool _loading = false;

  bool get loading => _loading;

  String? _error;

  String? get error => _error;
  @visibleForTesting
  set error(String? value) => _error = value;

  LoginResponse? _loginResponse;

  LoginResponse? get loginResponse => _loginResponse;
  @visibleForTesting
  set loginResponse(LoginResponse? value) => _loginResponse = value;

  RegisterRequest? _registerRequest;

  RegisterRequest? get registerRequest => _registerRequest;
  RegisterResponse? _registerResponse;

  RegisterResponse? get registerResponse => _registerResponse;

  /// Connexion utilisateur
  Future<void> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final request = LoginRequest(username: username, password: password);

      final response = await _authService.login(request);
      _loginResponse = response;
      if (response.success) {
        print(_loginResponse);
        _error = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        if (response.access_token != null) {
          await prefs.setString('access_token', response.access_token!);
        }
      } else {
        _error = response.message;
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode == 401) {
        print("Login failed: ${e.response?.data['message']}");
        _error = e.response?.data['message']; // Show message to user
      } else {
        print("Unexpected Dio error: ${e.message}");
        _error = "Une erreur est survenue.";
      }
    } catch (e) {
      print(e);
      _error = "Erreur lors de la connexion : ${e.toString()}";
    }

    _loading = false;
    notifyListeners();
  }

  /// Inscription utilisateur
  Future<void> register(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final request = RegisterRequest(username: username, password: password);
      final response = await _authService.register(request);
      _registerResponse = response;

      if (!response.success) {
        _error = response.message;
      } else {
        _error = null;
      }

    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode == 409) {
        print("Register failed: ${e.response?.data['message']}");
        _error = e.response?.data['message'];
      } else {
        print("Unexpected Dio error: ${e.message}");
        _error = "Une erreur est survenue.";
      }
    } catch (e) {
      _error = "Erreur lors de l'inscription : ${e.toString()}";
    }

    _loading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearLoginResponse() {
    _loginResponse = null;
    notifyListeners();
  }

}