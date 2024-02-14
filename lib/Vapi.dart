library vapi;

import 'dart:async';
import 'dart:convert';
import 'package:daily_flutter/daily_flutter.dart';

import 'models/exports/Exports.dart';

class VapiMessageContent {
  final String role;
  final String content;

  VapiMessageContent({required this.role, required this.content});

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }
}

class Vapi {
  // Function to send a message
  void sendMessage(VapiMessageContent messageContent) {
    // Assuming there's a method to send JSON data
    String jsonMessage = jsonEncode(messageContent.toJson());
    _sendJsonMessage(jsonMessage);
  }

  // Placeholder for the actual implementation of sending a message
  void _sendJsonMessage(String jsonMessage) {
    // Implementation to send the message JSON to the server or SDK's messaging system
    print("Sending message: $jsonMessage");
  }

  int addOne(int value) => value + 1;
}

/*
class Vapi {
  /// Returns [value] plus 1.
  /// Filler:
  int addOne(int value) => value + 1;
}
*/