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

    vapiJs.on("listening", (JSAny? data) {
      print("here");
    }.toJS);

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

    final callDataTmp = jsCallData.dartify() as Map<Object?, Object?>;
    final callData = Map<String, dynamic>.from(callDataTmp);
    
    final id = callData['id'];
    final orgId = callData['orgId'];
    final createdAt = DateTime.tryParse(callData['createdAt'])!;
    final updatedAt = DateTime.tryParse(callData['updatedAt'])!;
    final type = callData['type'];
    final monitorTmp = Map<String, dynamic>.from(callData['monitor']);
    final monitor = VapiCallMonitor.fromJson(monitorTmp);
    final transportTmp = Map<String, dynamic>.from(callData['transport']);
    final transport = VapiCallTransport.fromJson(transportTmp);
    final webCallUrl = callData['webCallUrl'];
    final assistantId = callData['assistantId'];
    final assistantOverrides = Map<String, dynamic>.from(callData['assistantOverrides']);

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

  /// This method manages the call lifecycle state.
  void _eventListener(String event, [JSAny? data]) {    
    switch (event) {
      case 'call-start':
        _emit(const VapiEvent('call-start'));
        break;

      case 'call-end':
        _emit(const VapiEvent('call-end'));
        break;

      case 'speech-start':
        _emit(const VapiEvent('speech-start'));
        break;

      case 'speech-end':
        _emit(const VapiEvent('speech-end'));
        break;

      case 'daily-participant-updated':
        final updatedParticipant = Map<String, dynamic>.from(data.dartify() as Map<Object?, Object?>);
        _emit(VapiEvent('daily-participant-updated', updatedParticipant));
        break;

      case 'volume-level':
        // emits a double value
        _emit(VapiEvent('volume-level', data.dartify()));
        break;

      case 'message':
        final message = Map<String, dynamic>.from(data.dartify() as Map<Object?, Object?>);
        final type = message['type'];
        
        if (type == "status-update") {
          final status = message['status'];
          if (status == "in-progress") {
            _status = VapiCallStatus.active;
          } else if (status == "ended") {
            _status = VapiCallStatus.ended;
          }
        }

        _emit(VapiEvent('message', message));
        break;

      case 'error':
        final error = Map<String, dynamic>.from(data.dartify() as Map<Object?, Object?>);
        _emit(VapiEvent('error', error));
        break;
    }
  }

  /// Helper to wrap event listeners for JS interop, accepting zero or one argument.
  JSFunction _wrapEventListener(String event) {
    // Accepts zero or one argument from JS
    return (([JSAny? data]) => _eventListener(event, data)).toJS;
  }

  /// Emits a VapiEvent to all listeners of this call.
  void _emit(VapiEvent event) {
    if (!_isDisposed) {
      _streamController.add(event);
    }
  }

  /// Sets up event listeners for the Vapi Web SDK.
  void _setupEventListeners() {
    _vapiJs.on('daily-participant-updated', _wrapEventListener('daily-participant-updated'));
    _vapiJs.on('call-start', _wrapEventListener('call-start'));
    _vapiJs.on('call-end', _wrapEventListener('call-end'));
    _vapiJs.on('speech-start', _wrapEventListener('speech-start'));
    _vapiJs.on('speech-end', _wrapEventListener('speech-end'));
    _vapiJs.on('volume-level', _wrapEventListener('volume-level'));
    _vapiJs.on('message', _wrapEventListener('message'));
    _vapiJs.on('error', _wrapEventListener('error'));
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
      throw const VapiCallEndedException();
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
      throw VapiException('Failed to set mute state - unknown error occurred', e);
    }
  }

  /// Sets the audio output device for this call using Vapi's audio device enum
  /// 
  /// Audio device management is typically handled by the browser
  /// This is a no-op on web platforms as audio routing is managed
  /// by the browser's media system and user preferences
  @override
  void setAudioDevice({VapiAudioDevice? device}) {
    throw UnimplementedError('Audio device management is typically handled by the browser - this is a no-op on web platforms');
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