import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:daily_flutter/daily_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../vapi_client_interface.dart';
import '../../vapi_call_interface.dart';
import '../../types/errors.dart';
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
  VapiMobileClient(
    this.publicKey, {
    this.apiBaseUrl = 'https://api.vapi.ai',
  }) {
    if (publicKey.isEmpty) {
      throw const VapiConfigurationException('Public key cannot be empty');
    }
  }

  @override
  Future<VapiCallInterface> start({
    String? assistantId,
    Map<String, dynamic>? assistant,
    Map<String, dynamic> assistantOverrides = const {},
    bool waitUntilActive = false,
  }) async {
    // Validate input parameters
    if (assistantId == null && assistant == null) {
      throw const VapiMissingAssistantException();
    }

    // Request necessary permissions for mobile
    await _requestMicrophonePermission();

    // Create the call on Vapi servers
    final apiResponse = await _createVapiCall(
      assistantId: assistantId,
      assistant: assistant,
      assistantOverrides: assistantOverrides,
    );

    // Create and configure the Daily client
    const clientCreationTimeout = Duration(seconds: 10);
    final client = await _createClientWithRetries(clientCreationTimeout);

    try {
      // Create and return the mobile call implementation
      return await VapiMobileCall.create(
        client, 
        apiResponse, 
        waitUntilActive: waitUntilActive
      );
    } catch (e) {
      // Cleanup on failure
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
      // Retry once if initially denied
      microphoneStatus = await Permission.microphone.request();
      
      if (microphoneStatus.isPermanentlyDenied) {
        // Guide user to app settings if permanently denied
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

    // Build request body based on provided parameters
    final Map<String, dynamic> requestBody = {
      'assistantOverrides': assistantOverrides,
    };

    if (assistantId != null) {
      requestBody['assistantId'] = assistantId;
    } else {
      requestBody['assistant'] = assistant;
    }

    final response = await http.post(
      url, 
      headers: headers, 
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 201) {
      throw VapiJoinFailedException('Failed to create call: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['webCallUrl'] == null) {
      throw const VapiJoinFailedException('Call URL not found in response');
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
        return await _createClientWithTimeout(clientCreationTimeoutDuration);
      } catch (error) {
        if (attempt >= maxRetries) {
          throw const VapiMaxRetriesExceededException();
        }
        
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(milliseconds: 100 * attempt));
      }
    }

    // This should never be reached due to the rethrow above
    throw const VapiMaxRetriesExceededException();
  }

  /// Creates a CallClient with a timeout.
  /// 
  /// Client creation can hang in poor network conditions.
  /// This method ensures creation fails fast if it takes too long.
  Future<CallClient> _createClientWithTimeout(Duration timeout) async {
    try {
      return await CallClient.create().timeout(
        timeout,
        onTimeout: () => throw const VapiClientTimeoutException(),
      );
    } catch (error) {
      if (error is VapiClientTimeoutException) {
        rethrow;
      }
      throw VapiClientCreationFailedException(error);
    }
  }

  @override
  String toString() {
    return 'VapiMobileClient(publicKey: ${publicKey.substring(0, 8)}...)';
  }
} 

/// Common interface for retrieving the implementation 
/// so conditional imports can be used.
/// 
/// [publicKey] is required for API authentication.
/// [apiBaseUrl] defaults to the production Vapi API.
getImplementation({
  required String publicKey,
  required String apiBaseUrl,
}) {
  return VapiMobileClient(publicKey, apiBaseUrl: apiBaseUrl);
}
