import 'package:json_annotation/json_annotation.dart';

part 'login_response.g.dart';

@JsonSerializable()
class LoginResponse {
  final String username;
  final bool success;
  final String message;
  final String? access_token;

  LoginResponse({
    required this.username,
    required this.success,
    required this.message,
    this.access_token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
  @override
  String toString() {
    return 'LoginResponse(success: $success, message: $message, username: $username, accessToken: $access_token)';
  }
}
