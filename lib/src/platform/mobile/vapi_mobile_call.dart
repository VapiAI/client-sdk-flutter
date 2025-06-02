import 'dart:async';
import 'dart:convert';

import 'package:daily_flutter/daily_flutter.dart';

import '../../vapi_call_interface.dart';
import '../../types/errors.dart';
import '../../types/vapi_event.dart';
import '../../types/vapi_audio_device.dart';
import '../../types/vapi_call_status.dart';

/// Represents the monitor configuration for a Vapi call.
/// 
/// Contains URLs for monitoring and controlling the call.
class VapiCallMonitor {
  /// WebSocket URL for listening to call events.
  final String listenUrl;
  
  /// HTTP URL for controlling the call.
  final String controlUrl;

  /// Creates a VapiCallMonitor instance.
  const VapiCallMonitor({
    required this.listenUrl,
    required this.controlUrl,
  });

  /// Creates a VapiCallMonitor from a JSON object.
  factory VapiCallMonitor.fromJson(Map<String, dynamic> json) {
    return VapiCallMonitor(
      listenUrl: json['listenUrl'] as String,
      controlUrl: json['controlUrl'] as String,
    );
  }
}

/// Represents the transport configuration for a Vapi call.
/// 
/// Contains information about the call transport provider and settings.
class VapiCallTransport {
  /// The transport provider (e.g., "daily").
  final String provider;
  
  /// Whether assistant video is enabled for this call.
  final bool assistantVideoEnabled;
  
  /// The call URL for the transport provider.
  final String callUrl;

  /// Creates a VapiCallTransport instance.
  const VapiCallTransport({
    required this.provider,
    required this.assistantVideoEnabled,
    required this.callUrl,
  });

  /// Creates a VapiCallTransport from a JSON object.
  factory VapiCallTransport.fromJson(Map<String, dynamic> json) {
    return VapiCallTransport(
      provider: json['provider'] as String,
      assistantVideoEnabled: json['assistantVideoEnabled'] as bool,
      callUrl: json['callUrl'] as String,
    );
  }
}

/// Represents an active voice AI call session.
/// 
/// This class encapsulates a single call and provides methods to interact
/// with the assistant, manage audio settings, and handle call lifecycle events.
/// 
/// Example usage:
/// ```dart
/// final vapiClient = VapiClient('your-public-key');
/// 
/// // Start a call and return immediately
/// final call = await vapiClient.start(assistantId: 'assistant-id');
/// 
/// // Or start a call and wait until the assistant is actively listening
/// final activeCall = await vapiClient.start(
///   assistantId: 'assistant-id',
///   waitUntilActive: true,
/// );
/// 
/// // Access call information
/// print('Call ID: ${call.id}');
/// print('Assistant ID: ${call.assistantId}');
/// print('Status: ${call.status}');
/// 
/// // Listen to events
/// call.onEvent.listen((event) {
///   print('Event: ${event.label}');
/// });
/// 
/// // Send a message during the call
/// await call.send({'message': 'Hello'});
/// 
/// // Check if call is still active
/// if (call.status == VapiCallStatus.active) {
///   await call.stop(); // This will trigger a 'call-end' event
/// }
/// 
/// // Clean up resources
/// call.dispose();
/// ```
class VapiMobileCall implements VapiCallInterface {
  /// The underlying Daily call client for this call.
  final CallClient _client;

  /// Stream controller for broadcasting Vapi events for this call.
  final _streamController = StreamController<VapiEvent>.broadcast();

  /// Completer for waiting until the call becomes active.
  final Completer<void> _activeCallCompleter = Completer<void>();

  /// Stream of Vapi events that occur during this call's lifecycle.
  /// 
  /// Events include:
  /// - `call-start`: When the assistant connects and starts listening
  /// - `call-end`: When the call ends (automatically emitted for all termination scenarios)
  /// - `call-error`: When an error occurs during the call
  /// - `message`: When a message is received from the assistant
  /// 
  /// The `call-end` event is guaranteed to be emitted whenever the call terminates,
  /// regardless of whether it was ended by calling [stop], network disconnection,
  /// or any other termination cause.
  @override
  Stream<VapiEvent> get onEvent => _streamController.stream;


  VapiCallStatus _status = VapiCallStatus.starting;

  /// The current status of this call.
  /// 
  /// Starts as [VapiCallStatus.starting], progresses to [VapiCallStatus.active] 
  /// when the assistant connects, and becomes [VapiCallStatus.ended] when the 
  /// call terminates. Once ended, no operations can be performed on this call instance.
  @override
  VapiCallStatus get status => _status;

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
  final String type;
  
  /// Monitor configuration for this call.
  final VapiCallMonitor monitor;
  
  /// Transport configuration for this call.
  final VapiCallTransport transport;
  
  /// Web call URL for joining the call.
  final String webCallUrl;
  
  /// Current call status from the API (e.g., "queued").
  final String apiStatus;
  
  /// ID of the assistant handling this call.
  @override
  final String assistantId;
  
  /// Assistant configuration overrides for this call.
  final Map<String, dynamic> assistantOverrides;

  /// Creates a new VapiCall instance.
  /// 
  /// This constructor is typically called internally by [VapiClient.start].
  VapiMobileCall._(
    this._client,
    this.id,
    this.orgId,
    this.createdAt,
    this.updatedAt,
    this.type,
    this.monitor,
    this.transport,
    this.webCallUrl,
    this.apiStatus,
    this.assistantId,
    this.assistantOverrides,
  ) {
    _setupEventListeners();
  }

  /// Factory method to create a VapiCall with an initialized client and API response data.
  /// 
  /// This method parses the API response, sets up the call client and joins the call.
  /// If [waitUntilActive] is true, it will wait until the assistant starts listening.
  static Future<VapiMobileCall> create(
    CallClient client, 
    Map<String, dynamic> apiResponse, {
    bool waitUntilActive = false,
  }) async {
    // Parse the API response
    final id = apiResponse['id'] as String;
    final orgId = apiResponse['orgId'] as String;
    final createdAt = DateTime.parse(apiResponse['createdAt'] as String);
    final updatedAt = DateTime.parse(apiResponse['updatedAt'] as String);
    final type = apiResponse['type'] as String;
    final monitor = VapiCallMonitor.fromJson(apiResponse['monitor'] as Map<String, dynamic>);
    final transport = VapiCallTransport.fromJson(apiResponse['transport'] as Map<String, dynamic>);
    final webCallUrl = apiResponse['webCallUrl'] as String;
    final apiStatus = apiResponse['status'] as String;
    final assistantId = apiResponse['assistantId'] as String;
    final assistantOverrides = Map<String, dynamic>.from(apiResponse['assistantOverrides'] as Map<String, dynamic>);
    
    final call = VapiMobileCall._(
      client,
      id,
      orgId,
      createdAt,
      updatedAt,
      type,
      monitor,
      transport,
      webCallUrl,
      apiStatus,
      assistantId,
      assistantOverrides,
    );
    
    await call._joinCall(webCallUrl);
    
    // Wait for the call to become active if requested
    if (waitUntilActive) {
      await call._activeCallCompleter.future;
    }
    
    return call;
  }

  /// Sets up event listeners for the call client.
  void _setupEventListeners() {
    _client.events.listen((event) {
      event.whenOrNull(
        callStateUpdated: (stateData) {
          switch (stateData.state) {
            case CallState.left:
              _status = VapiCallStatus.ended;
              emit(const VapiEvent("call-end"));
              break;
            case CallState.joined:
              break;
            default:
              break;
          }
        },
        participantLeft: (participantData) {
          if (participantData.info.isLocal) return;
          _client.leave();
        },
        appMessageReceived: (messageData, id) {
          _onAppMessage(messageData);
        },
        participantUpdated: (participantData) {
          if (participantData.info.username == "Vapi Speaker" &&
              participantData.media?.microphone.state == MediaState.playable) {
            _client.sendAppMessage(jsonEncode({'message': "playable"}), null);
          }
        },
        participantJoined: (participantData) {
          if (participantData.info.username == "Vapi Speaker" &&
              participantData.media?.microphone.state == MediaState.playable) {
            _client.sendAppMessage(jsonEncode({'message': "playable"}), null);
          }
        },
      );
    });
  }

  /// Joins the call using the provided web call URL.
  Future<void> _joinCall(String webCallUrl) async {
    const clientSettings = ClientSettingsUpdate.set(
      inputs: InputSettingsUpdate.set(
        microphone: MicrophoneInputSettingsUpdate.set(
          isEnabled: BoolUpdate.set(true)
        ),
        camera: CameraInputSettingsUpdate.set(
          isEnabled: BoolUpdate.set(false)
        ),
      )
    );

    await _client
        .join(
          url: Uri.parse(webCallUrl),
          clientSettings: clientSettings,
        )
        .catchError((e) {
      throw VapiJoinFailedException(e);
    });
  }

  /// Sends a message to the assistant during this call.
  /// 
  /// [message] can be any serializable object that will be JSON encoded
  /// and sent to the assistant.
  /// 
  /// Throws [VapiCallEndedException] if this call has ended.
  @override
  Future<void> send(dynamic message) async {
    if (_status == VapiCallStatus.ended) {
      throw const VapiCallEndedException();
    }
    await _client.sendAppMessage(jsonEncode(message), null);
  }

  /// Handles incoming app messages from the assistant.
  /// 
  /// Parses JSON messages and emits appropriate events.
  void _onAppMessage(String msg) {
    try {
      final parsedMessage = jsonDecode(msg);

      if (parsedMessage == "listening") {
        _status = VapiCallStatus.active;
        
        if (!_activeCallCompleter.isCompleted) {
          _activeCallCompleter.complete();
        }
        
        emit(const VapiEvent("call-start"));
      }

      emit(VapiEvent("message", parsedMessage));
    } catch (parseError) {
      // Silently ignore parse errors
    }
  }

  /// Stops this call and leaves the session.
  /// 
  /// After calling this method, the call will be marked as ended and
  /// no further operations can be performed on this call instance.
  /// 
  /// Throws [VapiCallEndedException] if this call has already ended.
  @override
  Future<void> stop() async {
    if (_status == VapiCallStatus.ended) {
      throw const VapiCallEndedException();
    }
    await _client.leave();
  }

  /// Mutes or unmutes the microphone during this call.
  /// 
  /// [muted] - true to mute the microphone, false to unmute.
  /// 
  /// Throws [VapiCallEndedException] if this call has ended.
  @override
  void setMuted(bool muted) {
    if (_status == VapiCallStatus.ended) {
      throw const VapiCallEndedException();
    }
    _client.updateInputs(
        inputs: InputSettingsUpdate.set(
      microphone:
          MicrophoneInputSettingsUpdate.set(isEnabled: BoolUpdate.set(!muted)),
    ));
  }

  /// Returns true if the microphone is currently muted.
  /// 
  /// Throws [VapiCallEndedException] if this call has ended.
  @override
  bool get isMuted {
    if (_status == VapiCallStatus.ended) {
      throw const VapiCallEndedException();
    }
    return _client.inputs.microphone.isEnabled == false;
  }

  /// Sets the audio output device for this call using Vapi's audio device enum.
  /// 
  /// [device] - The VapiAudioDevice to use for audio output.
  /// Available options:
  /// - [VapiAudioDevice.speakerphone] - Use the device's speakerphone
  /// - [VapiAudioDevice.wired] - Use wired headphones/earphones
  /// - [VapiAudioDevice.earpiece] - Use the device's earpiece
  /// - [VapiAudioDevice.bluetooth] - Use connected Bluetooth audio device
  /// 
  /// Throws [VapiCallEndedException] if this call has ended.
  @override
  void setAudioDevice({VapiAudioDevice? device}) {
    if (_status == VapiCallStatus.ended) {
      throw const VapiCallEndedException();
    }
    _client.setAudioDevice(
      deviceId: switch (device) {
        VapiAudioDevice.speakerphone => DeviceId.speakerPhone,
        VapiAudioDevice.wired => DeviceId.wired,
        VapiAudioDevice.earpiece => DeviceId.earpiece,
        VapiAudioDevice.bluetooth => DeviceId.bluetooth,
        null => throw const VapiException("Invalid audio device"),
      },
    );
  }

  /// Emits a VapiEvent to all listeners of this call.
  /// 
  /// This method is used internally to broadcast events to subscribers
  /// of the [onEvent] stream.
  void emit(VapiEvent event) {
    _streamController.add(event);
  }

  /// Disposes of resources used by this VapiCall instance.
  /// 
  /// Call this method when you're done using the VapiCall instance to
  /// clean up the event stream and prevent memory leaks.
  /// 
  /// Note: This will also dispose of the underlying call client.
  @override
  void dispose() {
    _client.dispose();
    _streamController.close();
  }
}
