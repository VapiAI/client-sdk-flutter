import 'dart:js_interop';
import 'dart:js_interop_unsafe'; // only used during registerWith library registration
import 'dart:async';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import '../../vapi_client_interface.dart';
import '../../vapi_call_interface.dart';
import '../../types/errors.dart';
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
        _scriptLoadedCompleter.completeError(e);
      });

      _scriptInjected = true;
    }
  }

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

    if (!_scriptInjected || !_scriptLoadedCompleter.isCompleted) {
      throw VapiConfigurationException('Vapi Web SDK script not loaded - injection status: $_scriptInjected, completion status: ${_scriptLoadedCompleter.isCompleted}');
    }

    try {
      _vapiJs = VapiJs(publicKey, apiBaseUrl as JSAny);
    } catch (e) {
      throw VapiConfigurationException('Failed to initialize Vapi Web SDK: $e');
    }
  }

  @override
  Future<VapiCallInterface> start({
    String? assistantId,
    Map<String, dynamic>? assistant,
    Map<String, dynamic> assistantOverrides = const {},
    Duration clientCreationTimeoutDuration = const Duration(seconds: 10),
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
        assistantConfig = assistant!.jsify() as JSAny;
      }

      // Prepare assistant overrides if provided
      final JSObject? jsOverrides = assistantOverrides.isNotEmpty 
          ? assistantOverrides.jsify() as JSObject
          : null;

      // Start the call using the Web SDK with modern Promise handling
      final jsPromise = _vapiJs.start(assistantConfig, jsOverrides);
      final jsCallData = await jsPromise.toDart;

      // Create and return the web call implementation
      return VapiWebCall.create(
        _vapiJs,
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
      _vapiJs.stop();
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
