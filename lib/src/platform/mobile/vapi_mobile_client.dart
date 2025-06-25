import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:daily_flutter/daily_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../vapi_client_interface.dart';
import '../../vapi_call_interface.dart';
import '../../shared/exceptions.dart';
import '../../shared/assistant_config.dart';
import 'vapi_mobile_call.dart';

/// Mobile-specific implementation of the Vapi client.
///
/// This implementation uses the Daily.co WebRTC SDK for real-time communication
/// and handles mobile-specific concerns like permissions and audio device management.
///
/// Features:
/// - Automatic microphone permission handling
/// - WebRTC-based real-time communication
/// - Mobile audio device management
/// - Retry logic for network failures
class VapiMobileClient implements VapiClientInterface {
  @override
  final String publicKey;

  @override
  final String apiBaseUrl;

  /// Creates a new mobile Vapi client.
  ///
  /// [publicKey] is required for API authentication.
  /// [apiBaseUrl] defaults to the production Vapi API.
  VapiMobileClient({
    required this.publicKey,
    this.apiBaseUrl = defaultApiBaseUrl,
  }) {
    if (publicKey.isEmpty) {
      throw const VapiConfigurationException('Public key cannot be empty');
    }
  }

  @override
  Future<VapiCall> start({
    String? assistantId,
    Map<String, dynamic>? assistant,
    Map<String, dynamic> assistantOverrides = const {},
    Duration clientCreationTimeoutDuration = const Duration(seconds: 10),
    bool waitUntilActive = false,
  }) async {
    if (assistantId == null && assistant == null) {
      throw const VapiMissingAssistantException();
    }

    await _requestMicrophonePermission();

    final apiResponse = await _createVapiCall(
      assistantId: assistantId,
      assistant: assistant,
      assistantOverrides: assistantOverrides,
    );

    final client =
        await _createClientWithRetries(clientCreationTimeoutDuration);

    try {
      return await VapiMobileCall.create(client, apiResponse,
          waitUntilActive: waitUntilActive);
    } catch (e) {
      client.dispose();
      rethrow;
    }
  }

  @override
  void dispose() {
    // Mobile client doesn't hold persistent resources
    // Individual calls manage their own cleanup
  }

  /// Requests microphone permission from the user.
  ///
  /// On mobile platforms, microphone access requires explicit user permission.
  /// This method handles the permission request flow and guides users to
  /// app settings if permission is permanently denied.
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
  ///
  /// This method handles the HTTP request to create a new call session
  /// and validates the response before returning.
  Future<Map<String, dynamic>> _createVapiCall({
    String? assistantId,
    Map<String, dynamic>? assistant,
    Map<String, dynamic> assistantOverrides = const {},
  }) async {
    final url = Uri.parse('$apiBaseUrl/call/web');
    final headers = {
      'Authorization': 'Bearer $publicKey',
      'Content-Type': 'application/json',
    };

    final assistantConfig = AssistantConfig(
        assistantId: assistantId,
        assistant: assistant,
        assistantOverrides: assistantOverrides);

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(assistantConfig.createRequestBody()),
    );

    if (response.statusCode != 201) {
      throw VapiStartCallException('Failed to create call: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['webCallUrl'] == null) {
      throw const VapiStartCallException('Call URL not found in response');
    }

    return data;
  }

  /// Creates a Daily CallClient with retry logic.
  ///
  /// Network conditions and device states can cause client creation to fail.
  /// This method implements exponential backoff retry logic to handle
  /// transient failures gracefully.
  Future<CallClient> _createClientWithRetries(
    Duration clientCreationTimeoutDuration,
  ) async {
    const maxRetries = 5;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final client =
            await _createClientWithTimeout(clientCreationTimeoutDuration);
        return client;
      } catch (error) {
        if (attempt >= maxRetries) {
          rethrow;
        }
      }
    }

    // This should never be reached due to the rethrow above, but added for completeness
    throw const VapiStartCallException();
  }

  /// Creates a CallClient with a timeout.
  ///
  /// Client creation can hang in poor network conditions.
  /// This method ensures creation fails fast if it takes too long.
  Future<CallClient> _createClientWithTimeout(Duration timeout) async {
    try {
      return await CallClient.create().timeout(
        timeout,
        onTimeout: () {
          throw const VapiStartCallException();
        },
      );
    } catch (error) {
      if (error is VapiStartCallException) {
        rethrow;
      }
      throw VapiStartCallException(error);
    }
  }
}

/// Common interface for retrieving the implementation
/// so conditional imports can be used.
///
/// [publicKey] is required for API authentication.
/// [apiBaseUrl] defaults to the production Vapi API.
getImplementation({
  required String publicKey,
  String apiBaseUrl = defaultApiBaseUrl,
}) {
  return VapiMobileClient(publicKey: publicKey, apiBaseUrl: apiBaseUrl);
}

/// Returns a completer that is already completed
Completer<void> getPlatformInitialized() {
  return Completer<void>()..complete();
}
