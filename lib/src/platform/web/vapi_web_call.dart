import 'dart:async';
import 'dart:js_interop';
import '../../vapi_call_interface.dart';
import '../../types/errors.dart';
import '../../types/vapi_event.dart';
import '../../types/vapi_audio_device.dart';
import '../../types/vapi_call_status.dart';
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

  // Call metadata (extracted from JavaScript call data)
  @override
  final String id;
  
  @override
  final String assistantId;
  
  @override
  final String orgId;
  
  @override
  final DateTime createdAt;
  
  @override
  final DateTime updatedAt;

  /// Creates a new VapiWebCall instance.
  /// 
  /// This constructor is typically called internally by [VapiWebClient.start].
  VapiWebCall._(
    this._vapiJs,
    this.id,
    this.assistantId,
    this.orgId,
    this.createdAt,
    this.updatedAt,
  ) {
    _setupEventListeners();
  }

  @override
  VapiCallStatus get status => _status;

  @override
  Stream<VapiEvent> get onEvent => _streamController.stream;

  /// Factory method to create a VapiWebCall with JavaScript call data.
  /// 
  /// This method parses the JavaScript call object, sets up event listeners,
  /// and optionally waits for the call to become active.
  static Future<VapiWebCall> create(
    VapiJs vapiJs,
    JSObject jsCallData, {
    bool waitUntilActive = false,
  }) async {
    // Parse the JavaScript call data
    final callData = jsCallData.dartify() as Map<String, dynamic>;
    
    final id = callData['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
    final assistantId = callData['assistantId']?.toString() ?? '';
    final orgId = callData['orgId']?.toString() ?? '';
    final createdAt = DateTime.tryParse(callData['createdAt']?.toString() ?? '') ?? DateTime.now();
    final updatedAt = DateTime.tryParse(callData['updatedAt']?.toString() ?? '') ?? DateTime.now();

    // Create the call instance
    final call = VapiWebCall._(
      vapiJs,
      id,
      assistantId,
      orgId,
      createdAt,
      updatedAt,
    );

    try {
      // Wait for the call to become active if requested
      if (waitUntilActive) {
        await call._activeCallCompleter.future;
      }

      return call;
    } catch (e) {
      // Cleanup on failure
      call.dispose();
      rethrow;
    }
  }

  /// Sets up event listeners for the Vapi Web SDK.
  /// 
  /// This method converts Web SDK events into Vapi events and
  /// manages the call lifecycle state.
  void _setupEventListeners() {
    // Set up JavaScript event listeners using Function.toJS
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
  void dispose() {
    if (_isDisposed) return;
    
    _isDisposed = true;
    _status = VapiCallStatus.ended;
    
    // Cleanup resources
    _streamController.close();
    
    if (!_activeCallCompleter.isCompleted) {
      _activeCallCompleter.completeError(const VapiCallEndedException());
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

  @override
  void setAudioDevice({VapiAudioDevice? device}) {
    if (_status == VapiCallStatus.ended || _isDisposed) {
      throw const VapiCallEndedException();
    }

    // Audio device management is typically handled by the browser
    // This is a no-op on web platforms as audio routing is managed
    // by the browser's media system and user preferences
    
    // Note: Web browsers handle audio device selection through
    // their own UI, so this method is provided for API compatibility
    // but doesn't perform any action on the web platform
  }

  /// Make the assistant say something during the call.
  /// 
  /// This is a web-specific feature available in the Vapi Web SDK.
  /// [message] is the text for the assistant to speak.
  /// [endCallAfterSpoken] optionally ends the call after speaking.
  void say(String message, {bool? endCallAfterSpoken}) {
    if (_status == VapiCallStatus.ended || _isDisposed) {
      throw const VapiCallEndedException();
    }

    try {
      _vapiJs.say(message, endCallAfterSpoken);
    } catch (e) {
      throw VapiException('Failed to make assistant speak', e);
    }
  }

  /// Emits a VapiEvent to all listeners of this call.
  void _emit(VapiEvent event) {
    if (!_isDisposed) {
      _streamController.add(event);
    }
  }

  @override
  String toString() {
    return 'VapiWebCall(id: $id, status: $status, assistantId: $assistantId)';
  }
} 