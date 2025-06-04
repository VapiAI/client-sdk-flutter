import 'exceptions.dart';

class AssistantConfig {
  final String? assistantId;
  final Map<String, dynamic>? assistant;
  final Map<String, dynamic> assistantOverrides;

  AssistantConfig({
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

  /// Creates a request body for the assistant configuration.
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

  /// Returns the assistant value, which can be either an assistantId or an assistant object.
  dynamic getAssistantValue() {
    return assistantId ?? assistant;
  }
}
