enum SpeechStatus {
  started,
  stopped,
}

enum SpeechRole {
  assistant,
  user,
}

extension SpeechStatusExtension on SpeechStatus {
  String get value {
    switch (this) {
      case SpeechStatus.started:
        return "started";
      case SpeechStatus.stopped:
        return "stopped";
      default:
        return "unknown";
    }
  }

  static SpeechStatus fromValue(String value) {
    switch (value) {
      case "started":
        return SpeechStatus.started;
      case "stopped":
        return SpeechStatus.stopped;
      default:
        throw ArgumentError("Invalid speech status value: $value");
    }
  }
}

extension SpeechRoleExtension on SpeechRole {
  String get value {
    switch (this) {
      case SpeechRole.assistant:
        return "assistant";
      case SpeechRole.user:
        return "user";
      default:
        return "unknown";
    }
  }

  static SpeechRole fromValue(String value) {
    switch (value) {
      case "assistant":
        return SpeechRole.assistant;
      case "user":
        return SpeechRole.user;
      default:
        throw ArgumentError("Invalid speech role value: $value");
    }
  }
}

class SpeechUpdate {
  final SpeechStatus status;
  final SpeechRole role;

  SpeechUpdate({required this.status, required this.role});

  factory SpeechUpdate.fromJson(Map<String, dynamic> json) {
    return SpeechUpdate(
      status: SpeechStatusExtension.fromValue(json['status'] as String),
      role: SpeechRoleExtension.fromValue(json['role'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.value,
      'role': role.value,
    };
  }
}