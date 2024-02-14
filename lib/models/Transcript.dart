enum TranscriptType {
  finalTranscript,
  partial,
}

extension TranscriptTypeExtension on TranscriptType {
  String get value {
    switch (this) {
      case TranscriptType.finalTranscript:
        return "final";
      case TranscriptType.partial:
        return "partial";
    }
  }

  static TranscriptType fromValue(String value) {
    switch (value) {
      case "final":
        return TranscriptType.finalTranscript;
      case "partial":
        return TranscriptType.partial;
      default:
        throw ArgumentError("Invalid transcript type value: $value");
    }
  }
}

enum TranscriptRole {
  assistant,
  user,
}

extension TranscriptRoleExtension on TranscriptRole {
  String get value {
    switch (this) {
      case TranscriptRole.assistant:
        return "assistant";
      case TranscriptRole.user:
        return "user";
    }
  }

  static TranscriptRole fromValue(String value) {
    switch (value) {
      case "assistant":
        return TranscriptRole.assistant;
      case "user":
        return TranscriptRole.user;
      default:
        throw ArgumentError("Invalid transcript role value: $value");
    }
  }
}

class Transcript {
  final TranscriptRole role;
  final TranscriptType transcriptType;
  final String transcript;

  Transcript({required this.role, required this.transcriptType, required this.transcript});

  factory Transcript.fromJson(Map<String, dynamic> json) {
    return Transcript(
      role: TranscriptRoleExtension.fromValue(json['role'] as String),
      transcriptType: TranscriptTypeExtension.fromValue(json['transcriptType'] as String),
      transcript: json['transcript'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role.value,
      'transcriptType': transcriptType.value,
      'transcript': transcript,
    };
  }
}