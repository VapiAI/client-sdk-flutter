import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:daily_flutter/daily_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'types/errors.dart';
import 'vapi_call.dart';

/// The main Vapi client for managing voice AI call creation and configuration.
/// 
/// This class provides a Flutter interface to the Vapi voice AI platform,
/// allowing you to create and start voice AI calls with assistants.
/// 
/// Example usage:
/// ```dart
/// final vapiClient = VapiClient('your-public-key');
/// 
/// // Start a call with an assistant
/// final call = await vapiClient.start(assistantId: 'assistant-id');
/// 
/// // Listen to events on the call
/// call.onEvent.listen((event) {
///   print('Event: ${event.label}');
/// });
/// 
/// // Send a message during the call
/// await call.send({'message': 'Hello'});
/// 
/// // Stop the call when done
/// await call.stop();
/// 
/// // Clean up resources
/// call.dispose();
/// ```
class VapiClient {
  /// The public API key for authenticating with the Vapi service.
  final String publicKey;

  /// The base URL for the Vapi API.
  final String apiBaseUrl;

  /// Creates a new VapiClient instance.
  /// 
  /// [publicKey] is required for API authentication.
  /// [apiBaseUrl] is optional and defaults to the production Vapi API.
  VapiClient(
    this.publicKey, {
    this.apiBaseUrl = 'https://api.vapi.ai',
  });

  /// Starts a voice AI call with the specified assistant.
  /// 
  /// Either [assistantId] or [assistant] must be provided:
  /// - [assistantId]: ID of a pre-configured assistant
  /// - [assistant]: Inline assistant configuration object
  /// 
  /// [assistantOverrides] allows you to override assistant settings for this call.
  /// [clientCreationTimeoutDuration] sets the timeout for creating the call client.
  /// 
  /// Returns a [VapiCall] instance that can be used to interact with the call.
  /// 
  /// Note: When this function returns, the call has been initialized successfully,
  /// but the [VapiCall.status] will remain in [VapiCallStatus.starting] until the
  /// assistant sends a "listening" event. This event may be delayed if the assistant
  /// has an initial monologue to deliver. The status will only switch to
  /// [VapiCallStatus.active] after receiving the "listening" event.
  /// 
  /// Throws:
  /// - [VapiMissingAssistantException] if neither assistantId nor assistant is provided
  /// - [VapiJoinFailedException] if joining the call fails
  /// - [VapiClientTimeoutException] if client creation times out
  /// - [VapiClientCreationFailedException] if client creation fails
  /// - [VapiMaxRetriesExceededException] if maximum retry attempts are exceeded
  Future<VapiCall> start({
    String? assistantId,
    dynamic assistant,
    Map<String, dynamic> assistantOverrides = const {},
    Duration clientCreationTimeoutDuration = const Duration(seconds: 10),
  }) async {
    await _requestMicrophonePermission();

    if (assistantId == null && assistant == null) {
      throw const VapiMissingAssistantException();
    }

    final apiResponse = await _createVapiCall(
      assistantId: assistantId,
      assistant: assistant,
      assistantOverrides: assistantOverrides,
    );

    final client = await _createClientWithRetries(clientCreationTimeoutDuration);

    try {
      return await VapiCall.create(client, apiResponse);
    } catch (e) {
      client.dispose();
      rethrow;
    }
  }

  /// Requests microphone permission from the user.
  Future<void> _requestMicrophonePermission() async {
    var microphoneStatus = await Permission.microphone.request();
    if (microphoneStatus.isDenied) {
      microphoneStatus = await Permission.microphone.request();
      if (microphoneStatus.isPermanentlyDenied) {
        await openAppSettings();
        return;
      }
    }
  }

  /// Creates a call on Vapi servers and returns the full API response.
  Future<Map<String, dynamic>> _createVapiCall({
    String? assistantId,
    dynamic assistant,
    Map<String, dynamic> assistantOverrides = const {},
  }) async {
    final baseUrl = '${apiBaseUrl}/call/web';
    final url = Uri.parse(baseUrl);
    final headers = {
      'Authorization': 'Bearer $publicKey',
      'Content-Type': 'application/json',
    };

    late final String body;
    if (assistantId != null) {
      body = jsonEncode({
        'assistantId': assistantId,
        'assistantOverrides': assistantOverrides
      });
    } else {
      body = jsonEncode({
        'assistant': assistant,
        'assistantOverrides': assistantOverrides
      });
    }

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode != 201) {
      throw VapiJoinFailedException('Failed to create call: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['webCallUrl'] == null) {
      throw const VapiJoinFailedException('Call URL not found in response');
    }

    return data;
  }

  /// Creates a call client with retry logic.
  /// 
  /// Attempts to create a Daily CallClient with timeout and retry mechanisms
  /// to handle potential network or initialization issues.
  Future<CallClient> _createClientWithRetries(
    Duration clientCreationTimeoutDuration,
  ) async {
    const maxRetries = 5;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final client = await _createClientWithTimeout(clientCreationTimeoutDuration);
        return client;
      } catch (error) {
        if (attempt >= maxRetries) {
          rethrow;
        }
      }
    }

    // This should never be reached due to the rethrow above, but added for completeness
    throw const VapiMaxRetriesExceededException();
  }

  /// Creates a CallClient with a timeout.
  Future<CallClient> _createClientWithTimeout(Duration timeout) async {
    try {
      return await CallClient.create().timeout(
        timeout,
        onTimeout: () {
          throw const VapiClientTimeoutException();
        },
      );
    } catch (error) {
      if (error is VapiClientTimeoutException) {
        rethrow;
      }
      throw VapiClientCreationFailedException(error);
    }
  }
} 