import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class AppMessage {
  final MessageType type;

  AppMessage({required this.type});

  factory AppMessage.fromJson(Map<String, dynamic> json) =>
      _$AppMessageFromJson(json);
  Map<String, dynamic> toJson() => _$AppMessageToJson(this);
}

enum MessageType {
  hang,
  @JsonValue('function-call')
  functionCall,
  transcript,
  @JsonValue('speech-update')
  speechUpdate,
  metadata,
  @JsonValue('conversation-update')
  conversationUpdate,
}
