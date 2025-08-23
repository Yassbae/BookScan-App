class UploadResponse {
  final String message;
  final List<Map<String, dynamic>>data;
  final String file;

  UploadResponse({
    required this.message,
    required this.data,
    required this.file,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      message: json['message'] ?? '',
      data: List<Map<String, dynamic>>.from(json['data']),
      file: json['file'] ?? '',
    );
  }
}
