import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'vapi_client_interface.dart';
import 'vapi_call_interface.dart';
import 'shared/exceptions.dart';

// Import implementations directly - tree shaking will handle unused code

import 'platform/mobile/vapi_mobile_client.dart' 
  if (dart.library.js_interop) 'platform/web/vapi_web_client.dart';

/// Factory class for creating platform-specific Vapi clients.
/// 
/// This class serves as the main entry point for the Vapi SDK.
/// It automatically selects the appropriate implementation based on the platform.
/// 
/// Example usage:
/// ```dart
/// final client = VapiClient('your-public-key');
/// 
/// // Start a call
/// final call = await client.start(assistantId: 'assistant-id');
/// 
/// // Listen to events
/// call.onEvent.listen((event) {
///   print('Event: ${event.label}');
/// });
/// 
/// // Clean up
/// call.dispose();
/// client.dispose();
/// ```
class VapiClient implements VapiClientInterface {

  /// Whether the underlying platform has been initialized.
  /// 
  /// This is useful to check if the client is ready to be used. 
  /// For example, when a [VapiClientCreationError] is thrown, 
  /// the platform might not been initialized yet.
  static Completer<void> get platformInitialized => getPlatformInitialized();
  
  /// The platform-specific implementation
  final VapiClientInterface _implementation;

  /// Private constructor that takes a platform-specific implementation
  VapiClient._(this._implementation);

  /// Creates a new Vapi client instance.
  /// 
  /// The appropriate implementation (web or mobile) is automatically selected
  /// based on the platform.
  /// 
  /// [publicKey] is required for API authentication.
  /// [apiBaseUrl] is optional and defaults to the production Vapi API.
  /// 
  /// Throws [VapiConfigurationException] if the public key is invalid.
  factory VapiClient(
    String publicKey, {
    String apiBaseUrl = 'https://api.vapi.ai',
  }) {
    if (publicKey.isEmpty) {
      throw const VapiConfigurationException('Public key cannot be empty');
    }

    return VapiClient._(
      getImplementation(
        publicKey: publicKey, 
        apiBaseUrl: apiBaseUrl,
      ),
    );
  }

  /// The public API key used for authentication
  @override
  String get publicKey => _implementation.publicKey;

  /// The base URL for the Vapi API
  @override
  String get apiBaseUrl => _implementation.apiBaseUrl;

  /// Starts a voice AI call with the specified assistant.
  /// 
  /// Either [assistantId] or [assistant] must be provided:
  /// - [assistantId]: ID of a pre-configured assistant
  /// - [assistant]: Inline assistant configuration object
  /// 
  /// [assistantOverrides] allows you to override assistant settings for this call.
  /// [waitUntilActive] determines whether to wait until the call is active before returning.
  /// When true, the method will wait for the assistant to start listening before returning.
  /// 
  /// Returns a [VapiCall] instance that can be used to interact with the call.
  /// 
  /// Throws:
  /// - [VapiMissingAssistantException] if neither assistantId nor assistant is provided
  /// - [VapiJoinFailedException] if joining the call fails
  /// - [VapiClientTimeoutException] if client creation times out
  /// - [VapiClientCreationFailedException] if client creation fails
  /// - [VapiMaxRetriesExceededException] if maximum retry attempts are exceeded
  @override
  Future<VapiCall> start({
    String? assistantId,
    Map<String, dynamic>? assistant,
    Map<String, dynamic> assistantOverrides = const {},
    Duration clientCreationTimeoutDuration = const Duration(seconds: 10),
    bool waitUntilActive = false,
  }) {
    return _implementation.start(
      assistantId: assistantId,
      assistant: assistant,
      assistantOverrides: assistantOverrides,
      clientCreationTimeoutDuration: clientCreationTimeoutDuration,
      waitUntilActive: waitUntilActive,
    );
  }

  /// Disposes of any resources held by the client.
  /// 
  /// This should be called when the client is no longer needed.
  @override
  void dispose() {
    _implementation.dispose();
  }

  /// Returns a string representation of the client.
  /// 
  /// This is useful for debugging and logging.
  @override
  String toString() {
    return 'VapiClient(platform: ${kIsWeb ? 'web' : 'mobile'}, publicKey: ${publicKey.substring(0, 8)}...)';
  }
}
