import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class Scan {
  final int id;
  final int userId;
  final DateTime timestamp;
  final List<String> images;
  final List<Map<String, dynamic>> ocrResult;

  Scan({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.images,
    required this.ocrResult,
  });

  factory Scan.fromJson(Map<String, dynamic> json) {
    return Scan(
      id: json['id'],
      userId: json['user_id'],
      timestamp: DateTime.parse(json['timestamp']),
      // Solution complète pour gérer les valeurs nulles
      images: (json['images'] as List<dynamic>?)?.whereType<String>().toList() ?? [],
      ocrResult: List<Map<String, dynamic>>.from(
        json['ocr_result'].map((item) => Map<String, dynamic>.from(item)),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'images': images,
      'ocr_result': ocrResult,
    };
  }
}
