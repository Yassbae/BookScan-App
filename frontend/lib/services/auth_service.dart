import 'package:dio/dio.dart';
import 'package:scan_book/models/login_request.dart';
import 'package:scan_book/models/register_response.dart';

import '../models/login_response.dart';
import 'package:retrofit/retrofit.dart';

import '../models/register_request.dart';
import '../utils/NetworkUtils.dart' as NetworkUtils;

part 'auth_service.g.dart';

@RestApi(baseUrl: NetworkUtils.baseUrl)
abstract class AuthService {
  factory AuthService(Dio dio, {String baseUrl}) = _AuthService;

  @POST("/applogin")
  Future<LoginResponse> login(@Body() LoginRequest request);

  @POST("/appregister")
  Future<RegisterResponse> register(@Body() RegisterRequest request);
}
