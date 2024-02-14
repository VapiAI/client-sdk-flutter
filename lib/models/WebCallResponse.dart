class WebCallResponse {
  final Uri webCallUrl;
  final String id;

  WebCallResponse({required this.webCallUrl, required this.id});

  factory WebCallResponse.fromJson(Map<String, dynamic> json) {
    return WebCallResponse(
      webCallUrl: Uri.parse(json['webCallUrl'] as String),
      id: json['id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'webCallUrl': webCallUrl.toString(),
      'id': id,
    };
  }
}