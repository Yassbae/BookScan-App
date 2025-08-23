import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/UploadResponse.dart';
import '../utils/NetworkUtils.dart' as NetworkUtils;

class UploadService {
  final Dio _dio;

  UploadService(this._dio);

  Future<UploadResponse> uploadImages(List<File> images) async {
    final formData = FormData();

    for (var image in images) {
      formData.files.add(
        MapEntry(
          "images",
          await MultipartFile.fromFile(
            image.path,
            filename: image.path.split("/").last,
          ),
        ),
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final response = await _dio.post(
      "${NetworkUtils.baseUrl}/appUpload",
      data: formData,
      options: Options(
        headers: {
          "Content-Type": "multipart/form-data",
          "Authorization": "Bearer $token",
        },
        // Optional: set timeouts
        // sendTimeout: 30000,
        // receiveTimeout: 30000,
      ),
    );

    return UploadResponse.fromJson(response.data);
  }
}
