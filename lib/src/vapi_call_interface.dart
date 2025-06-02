import 'dart:async';
import 'types/vapi_event.dart';
import 'types/vapi_call_status.dart';
import 'types/vapi_audio_device.dart';

/// Abstract interface defining the contract for Vapi call implementations.
/// 
/// This interface ensures consistent call management behavior across different
/// platforms while allowing platform-specific optimizations and features.
/// 
/// Each platform implementation handles the underlying communication
/// (WebRTC, WebSocket, etc.) while exposing a unified API.
abstract interface class VapiCallInterface {
  // Core call metadata - available on all platforms
  
  /// Unique identifier for this call session.
  String get id;
  
  /// ID of the assistant handling this call.
  String get assistantId;
  
  /// Organization ID associated with this call.
  String get orgId;
  
  /// Timestamp when this call was created.
  DateTime get createdAt;
  
  /// Timestamp when this call was last updated.
  DateTime get updatedAt;
  
  /// Current status of the call (starting, active, ended).
  VapiCallStatus get status;

  // Audio control functionality
  
  /// Whether the user's microphone is currently muted.
  bool get isMuted;
  
  /// Mutes or unmutes the user's microphone.
  /// 
  /// [muted] - true to mute, false to unmute
  void setMuted(bool muted);
  
  // Core call functionality
  
  /// Stream of events that occur during the call lifecycle.
  /// 
  /// Events include:
  /// - `call-start`: When the assistant connects and starts listening
  /// - `call-end`: When the call terminates (any reason)
  /// - `message`: Messages from the assistant or system
  /// - `speech-start`/`speech-end`: Speech detection events
  /// - `volume-level`: Real-time volume updates
  /// - `error`: Error notifications
  Stream<VapiEvent> get onEvent;
  
  /// Sends a message to the assistant during the call.
  /// 
  /// [message] should contain appropriate `type`, `role`, and `content` fields.
  /// Common message types include `add-message` for injecting system messages.
  /// 
  /// Throws [VapiException] if the message cannot be sent.
  Future<void> send(Map<String, dynamic> message);
  
  /// Stops the call and terminates the session.
  /// 
  /// This triggers a `call-end` event and releases call resources.
  /// After calling stop, no further operations can be performed on this call.
  Future<void> stop();
  
  /// Releases resources associated with this call.
  /// 
  /// Should be called after the call ends to prevent memory leaks.
  /// This is separate from [stop] to allow cleanup of ended calls.
  void dispose();
  
  // Platform-specific functionality (may be no-op on some platforms)
  
  /// Sets the audio device for the call.
  /// 
  /// This is primarily used on mobile platforms where multiple audio
  /// devices (speaker, earpiece, bluetooth) are available.
  /// 
  /// On web platforms, this may be a no-op as audio routing is
  /// typically handled by the browser.
  /// 
  /// [device] - The audio device to use for the call
  void setAudioDevice({VapiAudioDevice? device});
} 