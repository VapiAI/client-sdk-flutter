import 'dart:async';
import 'dart:js_interop';
import '../../vapi_call_interface.dart';
import '../../shared/errors.dart';
import '../../shared/exceptions.dart';
import '../../shared/vapi_event.dart';
import '../../shared/vapi_audio_device.dart';
import '../../shared/vapi_call_status.dart';
import '../../shared/assistant_config.dart';
import '../../shared/vapi_call_monitor.dart';
import '../../shared/vapi_call_transport.dart';
import 'vapi_js_interop.dart';

/// Web-specific implementation of a Vapi call using the Vapi Web SDK.
/// 
/// This implementation handles real-time voice communication in web browsers
/// using the Vapi Web SDK's built-in WebRTC capabilities.
/// 
/// Features:
/// - Browser-native WebRTC communication
/// - Automatic permission handling
/// - Event streaming and call management
/// - Web-optimized audio controls
class VapiWebCall implements VapiCallInterface {
  /// The underlying JavaScript Vapi instance
  final VapiJs _vapiJs;

  /// Stream controller for broadcasting Vapi events for this call.
  final _streamController = StreamController<VapiEvent>.broadcast();

  /// Completer for waiting until the call becomes active.
  final Completer<void> _activeCallCompleter = Completer<void>();

  /// Current status of this call.
  VapiCallStatus _status = VapiCallStatus.starting;

  /// Whether the call has been disposed.
  bool _isDisposed = false;

  /// Whether the microphone is currently muted
  bool _isMuted = false;

  /// Current status of the call (starting, active, ended).
  @override
  VapiCallStatus get status => _status;

  /// Stream of events that occur during the call lifecycle.
  @override
  Stream<VapiEvent> get onEvent => _streamController.stream;

  // Call metadata from Vapi API response
  /// Unique identifier for this call.
  @override
  final String id;
  
  /// Organization ID associated with this call.
  @override
  final String orgId;
  
  /// Timestamp when this call was created.
  @override
  final DateTime createdAt;
  
  /// Timestamp when this call was last updated.
  @override
  final DateTime updatedAt;
  
  /// Type of the call (e.g., "webCall").
  @override
  final String type;
  
  /// Monitor configuration for this call.
  @override
  final VapiCallMonitor monitor;
  
  /// Transport configuration for this call.
  @override
  final VapiCallTransport transport;
  
  /// Web call URL for joining the call.
  @override
  final String webCallUrl;
  
  /// ID of the assistant handling this call.
  @override
  final String assistantId;
  
  /// Assistant configuration overrides for this call.
  @override
  final Map<String, dynamic> assistantOverrides;

  /// Creates a new VapiWebCall instance.
  /// 
  /// This constructor is typically called internally by [VapiWebClient.start].
  VapiWebCall._(
    this._vapiJs,
    this.id,
    this.orgId,
    this.createdAt,
    this.updatedAt,
    this.type,
    this.monitor,
    this.transport,
    this.webCallUrl,
    this.assistantId,
    this.assistantOverrides,
  ) {
    _setupEventListeners();
  }

  /// Factory method to create a VapiWebCall with JavaScript call data.
  /// 
  /// This method parses the JavaScript call object, sets up event listeners,
  /// and optionally waits for the call to become active.
  static Future<VapiWebCall> create(
    VapiJs vapiJs,
    AssistantConfig assistantConfig, {
    bool waitUntilActive = false,
  }) async {
    late final JSObject jsCallData;
    try {
      jsCallData = await vapiJs.start(
        assistantConfig.getAssistantValue(asJs: true), 
        assistantConfig.assistantOverrides.jsify() as JSObject
      ).toDart;
    } catch (e) {
      // nothing we can do here apparently the future completes with an
      // error (see next line) and to catch it we have to wrap the await.
      // From tests the promise also fails when the underlying HTTP request
      // has succeeds with a non-200 status code - most likely Vapi Web SDK throws
      throw VapiClientCreationError('Failed to start web call: $e');
    }

    final callData = jsCallData.dartify() as Map<Object?, Object?>;
    
    final id = callData['id']!.toString();
    final orgId = callData['orgId']!.toString();
    final createdAt = DateTime.tryParse(callData['createdAt']!.toString())!;
    final updatedAt = DateTime.tryParse(callData['updatedAt']!.toString())!;
    final type = callData['type']!.toString();
    final monitor = VapiCallMonitor.fromJson(callData['monitor'] as Map<Object?, Object?>);
    final transport = VapiCallTransport.fromJson(callData['transport'] as Map<Object?, Object?>);
    final webCallUrl = callData['webCallUrl']!.toString();
    final assistantId = callData['assistantId']!.toString();
    final assistantOverrides = Map<String, dynamic>.from(callData['assistantOverrides'] as Map<String, dynamic>);

    final call = VapiWebCall._(
      vapiJs,
      id,
      orgId,
      createdAt,
      updatedAt,
      type,
      monitor,
      transport,
      webCallUrl,
      assistantId,
      assistantOverrides,
    );

    if (waitUntilActive) {
      await call._activeCallCompleter.future;
    }
    return call;
  }

  /// Sets up event listeners for the Vapi Web SDK.
  /// 
  /// This method converts Web SDK events into Vapi events and
  /// manages the call lifecycle state.
  void _setupEventListeners() {
    final onCallStart = ((JSAny? data) {
      _status = VapiCallStatus.active;
      
      if (!_activeCallCompleter.isCompleted) {
        _activeCallCompleter.complete();
      }
      
      _emit(const VapiEvent('call-start'));
    }).toJS;

    final onCallEnd = ((JSAny? data) {
      _status = VapiCallStatus.ended;
      _emit(const VapiEvent('call-end'));
    }).toJS;

    final onMessage = ((JSAny? data) {
      if (data != null && data.isA<JSObject>()) {
        final message = data.dartify() as Map<String, dynamic>;
        _emit(VapiEvent('message', message));
      }
    }).toJS;

    final onError = ((JSAny? error) {
      final errorData = error != null && error.isA<JSObject>() 
          ? error.dartify() as Map<String, dynamic>
          : {'message': error?.toString() ?? 'Unknown error'};
      _emit(VapiEvent('call-error', errorData));
    }).toJS;

    final onSpeechStart = ((JSAny? data) {
      _emit(const VapiEvent('speech-start'));
    }).toJS;

    final onSpeechEnd = ((JSAny? data) {
      _emit(const VapiEvent('speech-end'));
    }).toJS;

    final onVolumeLevel = ((JSAny? data) {
      if (data != null && data.isA<JSNumber>()) {
        final volume = (data as JSNumber).toDartDouble;
        _emit(VapiEvent('volume-level', volume));
      }
    }).toJS;

    // Register event listeners with the Vapi Web SDK
    _vapiJs.on('call-start', onCallStart);
    _vapiJs.on('call-end', onCallEnd);
    _vapiJs.on('message', onMessage);
    _vapiJs.on('error', onError);
    _vapiJs.on('speech-start', onSpeechStart);
    _vapiJs.on('speech-end', onSpeechEnd);
    _vapiJs.on('volume-level', onVolumeLevel);
  }

  @override
  Future<void> send(Map<String, dynamic> message) async {
    if (_status == VapiCallStatus.ended || _isDisposed) {
      throw const VapiCallEndedException();
    }

    try {
      final jsMessage = message.jsify() as JSObject;
      _vapiJs.send(jsMessage);
    } catch (e) {
      throw VapiException('Failed to send message', e);
    }
  }

  @override
  Future<void> stop() async {
    if (_status == VapiCallStatus.ended || _isDisposed) {
      return; // Already stopped
    }

    try {
      _vapiJs.stop();
    } catch (e) {
      // Ignore errors when stopping
    }
  }

  @override
  bool get isMuted => _isMuted;

  @override
  void setMuted(bool muted) {
    if (_status == VapiCallStatus.ended || _isDisposed) {
      throw const VapiCallEndedException();
    }
    
    try {
      _vapiJs.setMuted(muted);
      _isMuted = muted;
    } catch (e) {
      throw VapiException('Failed to set mute state', e);
    }
  }

  /// Sets the audio output device for this call using Vapi's audio device enum
  /// 
  /// Audio device management is typically handled by the browser
  /// This is a no-op on web platforms as audio routing is managed
  /// by the browser's media system and user preferences
  @override
  void setAudioDevice({VapiAudioDevice? device}) {
    if (_status == VapiCallStatus.ended || _isDisposed) {
      throw UnimplementedError('Audio device management is typically handled by the browser - this is a no-op on web platforms');
    }
  }

  /// Emits a VapiEvent to all listeners of this call.
  void _emit(VapiEvent event) {
    if (!_isDisposed) {
      _streamController.add(event);
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    
    _isDisposed = true;
    _status = VapiCallStatus.ended;
    
    _streamController.close();
    
    if (!_activeCallCompleter.isCompleted) {
      _activeCallCompleter.completeError(const VapiCallEndedException());
    }
  }
} 