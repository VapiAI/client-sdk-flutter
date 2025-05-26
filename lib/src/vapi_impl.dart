import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:daily_flutter/daily_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'types/errors.dart';
import 'types/vapi_event.dart';
import 'types/vapi_audio_device.dart';

/// The main Vapi client for managing voice AI calls.
/// 
/// This class provides a Flutter interface to the Vapi voice AI platform,
/// allowing you to start, manage, and interact with voice AI assistants.
/// 
/// Example usage:
/// ```dart
/// final vapi = Vapi('your-public-key');
/// 
/// // Listen to events
/// vapi.onEvent.listen((event) {
///   print('Event: ${event.label}');
/// });
/// 
/// // Start a call with an assistant
/// await vapi.start(assistantId: 'assistant-id');
/// 
/// // Send a message during the call
/// await vapi.send({'message': 'Hello'});
/// 
/// // Stop the call
/// await vapi.stop();
/// 
/// // Clean up resources
/// vapi.dispose();
/// ```
class Vapi {
  /// The public API key for authenticating with the Vapi service.
  final String publicKey;

  /// Optional custom base URL for the Vapi API.
  /// 
  /// Defaults to 'https://api.vapi.ai' if not provided.
  final String? apiBaseUrl;

  /// Stream controller for broadcasting Vapi events.
  final _streamController = StreamController<VapiEvent>.broadcast();

  /// Stream of Vapi events that occur during the call lifecycle.
  /// 
  /// Events include:
  /// - `call-start`: When the assistant connects and starts listening
  /// - `call-end`: When the call ends
  /// - `call-error`: When an error occurs during call setup
  /// - `message`: When a message is received from the assistant
  Stream<VapiEvent> get onEvent => _streamController.stream;

  /// The underlying Daily call client.
  CallClient? _client;

  /// Creates a new Vapi instance.
  /// 
  /// [publicKey] is required for API authentication.
  /// [apiBaseUrl] is optional and defaults to the production Vapi API.
  Vapi(this.publicKey, [this.apiBaseUrl]);

  /// Starts a voice AI call with the specified assistant.
  /// 
  /// Either [assistantId] or [assistant] must be provided:
  /// - [assistantId]: ID of a pre-configured assistant
  /// - [assistant]: Inline assistant configuration object
  /// 
  /// [assistantOverrides] allows you to override assistant settings for this call.
  /// [clientCreationTimeoutDuration] sets the timeout for creating the call client.
  /// 
  /// Throws:
  /// - [VapiCallInProgressException] if a call is already in progress
  /// - [VapiMissingAssistantException] if neither assistantId nor assistant is provided
  /// - [VapiJoinFailedException] if joining the call fails
  /// - [VapiClientTimeoutException] if client creation times out
  /// - [VapiClientCreationFailedException] if client creation fails
  /// - [VapiMaxRetriesExceededException] if maximum retry attempts are exceeded
  Future<void> start({
    String? assistantId,
    dynamic assistant,
    Map<String, dynamic> assistantOverrides = const {},
    Duration clientCreationTimeoutDuration = const Duration(seconds: 10),
  }) async {
    if (_client != null) {
      throw const VapiCallInProgressException();
    }

    print("🔄 ${DateTime.now()}: Vapi - Requesting Mic Permission...");
    var microphoneStatus = await Permission.microphone.request();
    if (microphoneStatus.isDenied) {
      microphoneStatus = await Permission.microphone.request();
      if (microphoneStatus.isPermanentlyDenied) {
        await openAppSettings();
        return;
      }
    }

    print("🆗 ${DateTime.now()}: Vapi - Mic Permission Granted");

    if (assistantId == null && assistant == null) {
      throw const VapiMissingAssistantException();
    }

    final baseUrl = '${apiBaseUrl ?? 'https://api.vapi.ai'}/call/web';
    final url = Uri.parse(baseUrl);
    final headers = {
      'Authorization': 'Bearer $publicKey',
      'Content-Type': 'application/json',
    };
    final body = assistantId != null
        ? jsonEncode({
            'assistantId': assistantId,
            'assistantOverrides': assistantOverrides
          })
        : jsonEncode(
            {'assistant': assistant, 'assistantOverrides': assistantOverrides});

    print("🔄 ${DateTime.now()}: Vapi - Preparing Call & Client...");

    // Create the Vapi call and client creation as futures
    final vapiCallFuture = http.post(url, headers: headers, body: body);
    final clientCreationFuture =
        _createClientWithRetries(clientCreationTimeoutDuration);

    // Wait for both futures to complete
    final results = await Future.wait([vapiCallFuture, clientCreationFuture]);

    final response = results[0] as http.Response;
    final client = results[1] as CallClient;

    _client = client;

    String? webCallUrl;

    if (response.statusCode == 201) {
      print("🆗 ${DateTime.now()}: Vapi - Vapi Call Ready");

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      webCallUrl = data['webCallUrl'] as String?;
      if (webCallUrl == null) {
        print('🆘 ${DateTime.now()}: Vapi - Vapi Call URL not found');
        emit(const VapiEvent("call-error"));
        return;
      }
    } else {
      client.dispose();
      _client = null;
      print(
          '🆘 ${DateTime.now()}: Vapi - Failed to create Vapi Call. Error: ${response.body}');
      emit(const VapiEvent("call-error"));
      return;
    }

    print("🔄 ${DateTime.now()}: Vapi - Joining Call...");

    client.events.listen((event) {
      event.whenOrNull(
        callStateUpdated: (stateData) {
          switch (stateData.state) {
            case CallState.leaving:
            case CallState.left:
              _client = null;
              print("⏹️  ${DateTime.now()}: Vapi - Call Ended.");
              emit(const VapiEvent("call-end"));
              break;
            case CallState.joined:
              print("🆗 ${DateTime.now()}: Vapi - Joined Call");
              break;
            default:
              break;
          }
        },
        participantLeft: (participantData) {
          if (participantData.info.isLocal) return;
          _client?.leave();
        },
        appMessageReceived: (messageData, id) {
          _onAppMessage(messageData);
        },
        participantUpdated: (participantData) {
          if (participantData.info.username == "Vapi Speaker" &&
              participantData.media?.microphone.state == MediaState.playable) {
            print("📤 ${DateTime.now()}: Vapi - Sending Ready...");
            client.sendAppMessage(jsonEncode({'message': "playable"}), null);
          }
        },
        participantJoined: (participantData) {
          if (participantData.info.username == "Vapi Speaker" &&
              participantData.media?.microphone.state == MediaState.playable) {
            print("📤 ${DateTime.now()}: Vapi - Sending Ready...");
            client.sendAppMessage(jsonEncode({'message': "playable"}), null);
          }
        },
      );
    });

    await client
        .join(
            url: Uri.parse(webCallUrl),
            clientSettings: const ClientSettingsUpdate.set(
                inputs: InputSettingsUpdate.set(
              microphone: MicrophoneInputSettingsUpdate.set(
                  isEnabled: BoolUpdate.set(true)),
              camera: CameraInputSettingsUpdate.set(
                  isEnabled: BoolUpdate.set(false)),
            )))
        .catchError((e) {
      throw VapiJoinFailedException(e);
    });
  }

  /// Creates a call client with retry logic.
  /// 
  /// Attempts to create a Daily CallClient with timeout and retry mechanisms
  /// to handle potential network or initialization issues.
  Future<CallClient> _createClientWithRetries(
    Duration clientCreationTimeoutDuration,
  ) async {
    var retries = 0;
    const maxRetries = 5;

    Future<CallClient> attemptCreation() async {
      return CallClient.create();
    }

    Future<CallClient> createWithTimeout() async {
      final completer = Completer<CallClient>();
      Future.delayed(clientCreationTimeoutDuration).then((_) {
        if (!completer.isCompleted) {
          print("⏳ ${DateTime.now()}: Vapi - Client creation timed out.");
          completer
              .completeError(const VapiClientTimeoutException());
        }
      });

      attemptCreation().then((client) {
        if (!completer.isCompleted) {
          completer.complete(client);
        }
      }).catchError((error) {
        if (!completer.isCompleted) {
          completer.completeError(VapiClientCreationFailedException(error));
        }
      });

      return completer.future;
    }

    while (retries < maxRetries) {
      try {
        print(
            "🔄 ${DateTime.now()}: Vapi - Creating client (Attempt ${retries + 1})...");
        final client = await createWithTimeout();
        print("🆗 ${DateTime.now()}: Vapi - Client Created");
        return client;
      } catch (e) {
        retries++;
        if (retries >= maxRetries) {
          print(
              '🆘 ${DateTime.now()}: Vapi - Failed to create client after $maxRetries attempts.');
          rethrow;
        }
      }
    }

    throw const VapiMaxRetriesExceededException();
  }

  /// Sends a message to the assistant during an active call.
  /// 
  /// [message] can be any serializable object that will be JSON encoded
  /// and sent to the assistant.
  /// 
  /// Throws [VapiNoCallException] if no call is currently in progress.
  Future<void> send(dynamic message) async {
    if (_client == null) {
      throw const VapiNoCallException();
    }
    await _client!.sendAppMessage(jsonEncode(message), null);
  }

  /// Handles incoming app messages from the assistant.
  /// 
  /// Parses JSON messages and emits appropriate events.
  void _onAppMessage(String msg) {
    try {
      final parsedMessage = jsonDecode(msg);

      if (parsedMessage == "listening") {
        print("✅ ${DateTime.now()}: Vapi - Assistant Connected.");
        emit(const VapiEvent("call-start"));
      }

      emit(VapiEvent("message", parsedMessage));
    } catch (parseError) {
      print("Error parsing message data: $parseError");
    }
  }

  /// Stops the current call and leaves the session.
  /// 
  /// Throws [VapiNoCallException] if no call is currently in progress.
  Future<void> stop() async {
    if (_client == null) {
      throw const VapiNoCallException();
    }
    await _client!.leave();
  }

  /// Mutes or unmutes the microphone during a call.
  /// 
  /// [muted] - true to mute the microphone, false to unmute.
  /// 
  /// Throws [VapiNoCallException] if no call is currently in progress.
  void setMuted(bool muted) {
    if (_client == null) {
      throw const VapiNoCallException();
    }
    _client!.updateInputs(
        inputs: InputSettingsUpdate.set(
      microphone:
          MicrophoneInputSettingsUpdate.set(isEnabled: BoolUpdate.set(!muted)),
    ));
  }

  /// Returns true if the microphone is currently muted.
  /// 
  /// Throws [VapiNoCallException] if no call is currently in progress.
  bool isMuted() {
    if (_client == null) {
      throw const VapiNoCallException();
    }
    return _client!.inputs.microphone.isEnabled == false;
  }

  /// Sets the audio output device for the call.
  /// 
  /// [deviceId] - The Daily DeviceId to use for audio output.
  /// 
  /// **Deprecated**: Use [setVapiAudioDevice] instead. This method is deprecated 
  /// because it requires users to depend on daily_flutter directly.
  /// 
  /// Throws [VapiNoCallException] if no call is currently in progress.
  @Deprecated(
    "Use [setVapiAudioDevice] instead. Deprecated because unusable if user does not depend of daily_flutter",
  )
  void setAudioDevice({required DeviceId deviceId}) {
    if (_client == null) {
      throw const VapiNoCallException();
    }
    _client!.setAudioDevice(deviceId: deviceId);
  }

  /// Sets the audio output device for the call using Vapi's audio device enum.
  /// 
  /// [device] - The VapiAudioDevice to use for audio output.
  /// Available options:
  /// - [VapiAudioDevice.speakerphone] - Use the device's speakerphone
  /// - [VapiAudioDevice.wired] - Use wired headphones/earphones
  /// - [VapiAudioDevice.earpiece] - Use the device's earpiece
  /// - [VapiAudioDevice.bluetooth] - Use connected Bluetooth audio device
  /// 
  /// Throws [VapiNoCallException] if no call is currently in progress.
  void setVapiAudioDevice({required VapiAudioDevice device}) {
    if (_client == null) {
      throw const VapiNoCallException();
    }
    _client!.setAudioDevice(
      deviceId: switch (device) {
        VapiAudioDevice.speakerphone => DeviceId.speakerPhone,
        VapiAudioDevice.wired => DeviceId.wired,
        VapiAudioDevice.earpiece => DeviceId.earpiece,
        VapiAudioDevice.bluetooth => DeviceId.bluetooth,
      },
    );
  }

  /// Emits a VapiEvent to all listeners.
  /// 
  /// This method is used internally to broadcast events to subscribers
  /// of the [onEvent] stream.
  void emit(VapiEvent event) {
    _streamController.add(event);
  }

  /// Disposes of resources used by this Vapi instance.
  /// 
  /// Call this method when you're done using the Vapi instance to
  /// clean up the event stream and prevent memory leaks.
  void dispose() {
    _streamController.close();
  }
} 