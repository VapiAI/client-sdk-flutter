import 'dart:js_interop';
import 'dart:js_interop_unsafe'; // only used during registerWith library registration
import 'dart:async';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import '../../vapi_client_interface.dart';
import '../../vapi_call_interface.dart';
import '../../shared/exceptions.dart';
import '../../shared/errors.dart';
import '../../shared/assistant_config.dart';
import 'vapi_web_call.dart';
import 'vapi_js_interop.dart';

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
  late final VapiJs _vapiJs;

  /// The Vapi Web SDK CDN URL with the currenly supported version
  static const _cdnUrl = "https://cdn.jsdelivr.net/npm/@vapi-ai/web@2.3.1/+esm";

  /// Whether the Vapi Web SDK script has been injected into the document
  static bool _scriptInjected = false;

  /// A completer that is completed when the Vapi Web SDK script is loaded
  static final _scriptLoadedCompleter = Completer<void>();

  /// Called by Flutter's web plugin registrant at startup.
  static void registerWith(Registrar registrar) {
    if (!_scriptInjected) {
      final cdnUrlJs = '$_cdnUrl'.toJS;
      final modulePromise = importModule(cdnUrlJs).toDart;
      
      modulePromise.then((module) {
        final esModule = module.getProperty('default'.toJS);
        final moduleName = 'VapiEsModule'.toJS;
        globalContext.setProperty(moduleName, esModule);
        _scriptLoadedCompleter.complete();
      }).catchError((e) {
        final error = VapiClientCreationError('Failed to load Vapi Web SDK: $e');
        _scriptLoadedCompleter.completeError(error);
      });

      _scriptInjected = true;
    }
  }

  /// Creates a new web Vapi client.
  /// 
  /// [publicKey] is required for API authentication.
  /// [apiBaseUrl] is not used in web implementation as the Vapi Web SDK
  /// handles API communication internally.
  VapiWebClient({
    required this.publicKey,
    this.apiBaseUrl = defaultApiBaseUrl,
  }) {
    if (publicKey.isEmpty) {
      throw const VapiConfigurationException('Public key cannot be empty');
    }

    if (!_scriptInjected || !_scriptLoadedCompleter.isCompleted) {
      throw VapiClientCreationError('Vapi Web SDK script not loaded - injection status: $_scriptInjected, completion status: ${_scriptLoadedCompleter.isCompleted}');
    }

    try {
      _vapiJs = VapiJs(publicKey, apiBaseUrl as JSAny);
    } catch (e) {
      throw VapiConfigurationException('Failed to initialize Vapi Web SDK: $e');
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
    final assistantConfig = AssistantConfig(
      assistantId: assistantId, 
      assistant: assistant, 
      assistantOverrides: assistantOverrides
    );

    try {
      return VapiWebCall.create(
        _vapiJs,
        assistantConfig,
        waitUntilActive: waitUntilActive,
      );
    } catch (e) {
      if (e is VapiException || e is VapiError) {
        rethrow;
      }
      throw VapiStartCallException('Failed to start web call: $e');
    }
  }

  @override
  void dispose() {
    try {
      _vapiJs.stop();
    } catch (e) {
      // Nothing we can do here
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
  return VapiWebClient(publicKey: publicKey, apiBaseUrl: apiBaseUrl);
}

/// Returns a completer that is completed when the Vapi Web SDK script is loaded
Completer<void> getPlatformInitialized() {
  return VapiWebClient._scriptLoadedCompleter;
}
