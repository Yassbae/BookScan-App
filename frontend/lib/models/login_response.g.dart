// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(
      username: json['username'] as String,
      success: json['success'] as bool,
      message: json['message'] as String,
      access_token: json['access_token'] as String?,
    );

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{
      'username': instance.username,
      'success': instance.success,
      'message': instance.message,
      'access_token': instance.access_token,
    };
