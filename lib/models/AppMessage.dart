enum MessageType {
    hang, 
    functionCall, 
    transcript,
    speechUpdate,
    metadata,
    conversationUpdate, 
}

extension MessageTypeExention on MessageType {
  String get value {
    switch (this) {
      case MessageType.hang:
        return "hang";
      case MessageType.functionCall:
        return "function-call";
      case MessageType.transcript:
        return "transcription";
      case MessageType.speechUpdate:
        return "speech-update";
      case MessageType.metadata:
        return "metadata";
      case MessageType.conversationUpdate:
        return "conversation-update";
    }
  }

  static MessageType fromValue(String value) {
    switch (value) {
      case "hang":
        return MessageType.hang;
      case "function-call":
        return MessageType.functionCall;
      case "transcript":
        return MessageType.transcript;
      case "speech-update":
        return MessageType.speechUpdate;
      case "metadata":
        return MessageType.metadata;
      case "conversation-update":
        return MessageType.conversationUpdate;
      default:
        throw ArgumentError("Invalid message type value: $value");
    }
  }
}