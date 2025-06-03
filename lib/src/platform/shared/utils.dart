import '../../shared/exceptions.dart';

class CallConfig {
  final String? assistantId;
  final Map<String, dynamic>? assistant;
  final Map<String, dynamic> assistantOverrides;

  CallConfig({
    this.assistantId,
    this.assistant,
    this.assistantOverrides = const {},
  }) {
    if ((assistantId == null && assistant == null) ||
        (assistantId != null && assistant != null)) {
      throw const VapiConfigurationException(
        'Either assistantId or assistant must be set, but not both.',
      );
    }
  }

  Map<String, dynamic> createRequestBody() {
    if (assistantId != null) {
      return {
        'assistantId': assistantId,
        'assistantOverrides': assistantOverrides,
      };
    } else {
      return {
        'assistant': assistant,
        'assistantOverrides': assistantOverrides,
      };
    }
  }

  dynamic get assistantValue => assistantId ?? assistant;
}