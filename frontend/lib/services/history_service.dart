import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_request.dart';
import '../utils/NetworkUtils.dart' as NetworkUtils;

class HistoryService {
  final Dio _dio = Dio();

  HistoryService() {
    _dio.options.baseUrl = NetworkUtils.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  Future<List<Scan>> getScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    try {
      final response = await _dio.get(
        '/scanHistory',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final data = response.data as List<dynamic>;

      return data.map((item) => Scan.fromJson(item)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch scan history: ${e.message}');
    }
  }
  Future<void> deleteScans(List<int> scanIds) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    try {
      final response = await _dio.post(
        '/delete-scans',
        data: {"ids": scanIds},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode != 200) {
        throw Exception('Delete Failed ${response.data}');
      }
    } on DioException catch (e) {
      throw Exception('Delete Failed : ${e.message}');
    }
  }


}
