import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:scan_book/models/login_request.dart';
import 'package:scan_book/models/login_response.dart';
import 'package:scan_book/models/register_request.dart';
import 'package:scan_book/models/register_response.dart';
import 'package:scan_book/services/auth_service.dart';
import 'package:scan_book/viewmodels/AuthViewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'auth_viewmodel_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  late AuthViewModel viewModel;
  late MockAuthService mockAuthService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockAuthService = MockAuthService();
    viewModel = AuthViewModel();
    viewModel.setAuthService(mockAuthService);
  });

  group('login()', () {
    final successResponse = LoginResponse(
      username: 'test',
      success: true,
      message: 'Success',
      access_token: 'fake_token',
    );
    final failureResponse = LoginResponse(
      username: 'test',
      success: false,
      message: 'Invalid credentials',
    );

    test('successful login - updates SharedPreferences', () async {
      when(mockAuthService.login(any))
          .thenAnswer((_) async => successResponse);

      await viewModel.login('test', '123456');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('isLoggedIn'), true);
      expect(prefs.getString('access_token'), 'fake_token');
    });

    test('failed login - sets error message', () async {
      when(mockAuthService.login(any))
          .thenAnswer((_) async => failureResponse);

      await viewModel.login('test', 'wrong_password');
      expect(viewModel.error, 'Invalid credentials');
    });

    test('handles DioException (401)', () async {
      when(mockAuthService.login(any)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/login'),
            statusCode: 401,
            data: {'message': 'Unauthorized'},
          ),
        ),
      );

      await viewModel.login('test', '123456');
      expect(viewModel.error, 'Unauthorized');
    });

    test('handles generic DioException', () async {
      when(mockAuthService.login(any)).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/login')),
      );

      await viewModel.login('test', '123456');
      expect(viewModel.error, "Une erreur est survenue.");
    });

    test('handles general exceptions', () async {
      when(mockAuthService.login(any))
          .thenThrow(Exception('Erreur de connexion'));

      await viewModel.login('test', '123456');
      expect(viewModel.error, 'Erreur lors de la connexion : Exception: Erreur de connexion');
    });
  });

  group('register()', () {
    test('successful registration - clears errors', () async {
      when(mockAuthService.register(any))
          .thenAnswer((_) async => RegisterResponse(
          success: true,
          message: 'Success'
      ));

      await viewModel.register('new_user', 'ValidPass123!');

      expect(viewModel.error, isNull);
      verify(mockAuthService.register(any)).called(1);
    });

    test('failed registration - sets error message', () async {
      when(mockAuthService.register(any))
          .thenAnswer((_) async => RegisterResponse(
          success: false,
          message: 'Username exists'
      ));

      await viewModel.register('new_user', 'ValidPass123!');

      expect(viewModel.error, 'Username exists');
    });

    test('handles 409 conflict', () async {
      when(mockAuthService.register(any)).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/register'),
            response: Response(
                requestOptions: RequestOptions(path: '/register'),
                statusCode: 409,
                data: {'message': 'Conflict'}
            ),
          )
      );

      await viewModel.register('new_user', 'ValidPass123!');

      expect(viewModel.error, 'Conflict');
    });

    test('handles generic DioException', () async {
      when(mockAuthService.register(any)).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/register')),
      );

      await viewModel.register('new_user', 'ValidPass123!');
      expect(viewModel.error, "Une erreur est survenue.");
    });

    test('handles general exceptions', () async {
      when(mockAuthService.register(any)).thenThrow(Exception('Network error'));

      await viewModel.register('new_user', 'ValidPass123!');
      expect(viewModel.error, 'Erreur lors de l\'inscription : Exception: Network error');
    });
  });

  group('clear methods', () {
    test('clearError should set error to null', () {
      viewModel.error = "Initial error";
      viewModel.clearError();
      expect(viewModel.error, isNull);
    });

    test('clearLoginResponse should set loginResponse to null', () {
      viewModel.loginResponse = LoginResponse(
          username: "test", success: true, message: "test");
      viewModel.clearLoginResponse();
      expect(viewModel.loginResponse, isNull);
    });
  });
}