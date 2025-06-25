import 'vapi_call_interface.dart';

const String defaultApiBaseUrl = 'https://api.vapi.ai';

/// Abstract interface defining the contract for Vapi client implementations.
///
/// This interface ensures consistent behavior across different platforms
/// (mobile, web, desktop) while allowing platform-specific optimizations.
///
/// All platform-specific implementations must conform to this interface,
/// guaranteeing a unified API experience for developers.
abstract interface class VapiClientInterface {
  /// The public API key used for authentication with Vapi services.
  ///
  /// This key is provided by Vapi and identifies your application.
  String get publicKey;

  /// The base URL for the Vapi API.
  ///
  /// Defaults to the production Vapi API but can be overridden for
  /// testing or custom deployments.
  String get apiBaseUrl;

  /// Starts a voice AI call with the specified configuration.
  ///
  /// Either [assistantId] or [assistant] must be provided:
  /// - [assistantId]: ID of a pre-configured assistant from your Vapi dashboard
  /// - [assistant]: Inline assistant configuration for ephemeral assistants
  ///
  /// [assistantOverrides] allows overriding assistant settings or setting template variables.
  /// [waitUntilActive] determines whether to wait until the call becomes active before returning.
  ///
  /// Returns a [VapiCall] instance for interacting with the call.
  ///
  /// Throws [VapiException] if the call cannot be started.
  Future<VapiCall> start({
    String? assistantId,
    Map<String, dynamic>? assistant,
    Map<String, dynamic> assistantOverrides = const {},
    Duration clientCreationTimeoutDuration = const Duration(seconds: 10),
    bool waitUntilActive = false,
  });

  /// Releases any resources held by this client.
  ///
  /// Should be called when the client is no longer needed to prevent
  /// memory leaks and ensure proper cleanup.
  void dispose();
}
