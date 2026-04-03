class OcrResponse {
  final bool success;
  final String message;
  final int totalFiles;
  final List<OcrResult> results;
  final String extractedText;
  final bool fullTextAvailable;

  OcrResponse({
    required this.success,
    required this.message,
    required this.totalFiles,
    required this.results,
    required this.extractedText,
    required this.fullTextAvailable,
  });

  factory OcrResponse.fromJson(Map<String, dynamic> json) {
    return OcrResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      totalFiles: json['totalFiles'] ?? 0,
      results: (json['results'] as List? ?? [])
          .map((e) => OcrResult.fromJson(e))
          .toList(),
      extractedText: json['extractedText'] ?? '',
      fullTextAvailable: json['fullTextAvailable'] ?? false,
    );
  }
}

class OcrResult {
  final String filename;
  final String status;
  final int textLength;

  OcrResult({
    required this.filename,
    required this.status,
    required this.textLength,
  });

  factory OcrResult.fromJson(Map<String, dynamic> json) {
    return OcrResult(
      filename: json['filename'] ?? '',
      status: json['status'] ?? '',
      textLength: json['textLength'] ?? 0,
    );
  }
}
