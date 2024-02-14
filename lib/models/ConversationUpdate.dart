enum Role {
  user,
  assistant,
  system,
}

extension RoleExtension on Role {
  String get value {
    switch (this) {
      case Role.user:
        return "user";
      case Role.assistant:
        return "assistant";
      case Role.system:
        return "system";
      default:
        return "unknown";
    }
  }

  static Role fromValue(String value) {
    switch (value) {
      case "user":
        return Role.user;
      case "assistant":
        return Role.assistant;
      case "system":
        return Role.system;
      default:
        throw ArgumentError("Invalid role value: $value");
    }
  }
}

class Message {
  final Role role;
  final String content;

  Message({required this.role, required this.content});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: RoleExtension.fromValue(json['role'] as String),
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role.value,
      'content': content,
    };
  }
}

class ConversationUpdate {
  final List<Message> conversation;

  ConversationUpdate({required this.conversation});

  factory ConversationUpdate.fromJson(Map<String, dynamic> json) {
    var conversationList = json['conversation'] as List;
    List<Message> messages = conversationList.map((i) => Message.fromJson(i)).toList();
    return ConversationUpdate(conversation: messages);
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation': conversation.map((message) => message.toJson()).toList(),
    };
  }
}