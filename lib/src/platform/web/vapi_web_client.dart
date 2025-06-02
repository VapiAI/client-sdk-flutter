import 'dart:async';
import 'dart:js_interop';
import '../../vapi_client_interface.dart';
import '../../vapi_call_interface.dart';
import '../../types/errors.dart';
import 'js_interop.dart';
import 'vapi_web_call.dart';

/// Web-specific implementation of the Vapi client.
/// 
/// This implementation uses the Vapi Web SDK (@vapi-ai/web) through JavaScript interop
/// for browser-based real-time communication.
/// 
/// Features:
/// - Browser-native WebRTC through Vapi Web SDK
/// - Automatic browser permission handling
/// - JavaScript interop for seamless integration
/// - Web-optimized performance
class VapiWebClient implements VapiClientInterface {
  @override
  final String publicKey;

  @override
  final String apiBaseUrl;

  /// The underlying JavaScript Vapi instance
  late final VapiJS _vapi;

  /// Creates a new web Vapi client.
  /// 
  /// [publicKey] is required for API authentication.
  /// [apiBaseUrl] is not used in web implementation as the Vapi Web SDK
  /// handles API communication internally.
  VapiWebClient(
    this.publicKey, {
    this.apiBaseUrl = 'https://api.vapi.ai',
  }) {
    if (publicKey.isEmpty) {
      throw const VapiConfigurationException('Public key cannot be empty');
    }

    try {
      _vapi = VapiJS(publicKey);
    } catch (e) {
      throw VapiConfigurationException('Failed to initialize Vapi Web SDK: $e');
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

    try {
      // Prepare assistant configuration for JavaScript
      final JSAny assistantConfig;
      if (assistantId != null) {
        assistantConfig = assistantId.toJS;
      } else {
        assistantConfig = dartMapToJS(assistant!);
      }

      // Prepare assistant overrides if provided
      final JSObject? jsOverrides = assistantOverrides.isNotEmpty 
          ? dartMapToJS(assistantOverrides)
          : null;

      // Start the call using the Web SDK with modern Promise handling
      final jsPromise = _vapi.start(assistantConfig, jsOverrides);
      final jsCallData = await jsPromise.toDart;

      // Create and return the web call implementation
      return VapiWebCall.create(
        _vapi,
        jsCallData,
        waitUntilActive: waitUntilActive,
      );
    } catch (e) {
      if (e is VapiException) {
        rethrow;
      }
      throw VapiJoinFailedException('Failed to start web call: $e');
    }
  }

  @override
  void dispose() {
    // Stop any active calls
    try {
      _vapi.stop();
    } catch (e) {
      // Ignore errors during cleanup
    }
  }

  @override
  String toString() {
    return 'VapiWebClient(publicKey: ${publicKey.substring(0, 8)}...)';
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
  return VapiWebClient(publicKey, apiBaseUrl: apiBaseUrl);
}
