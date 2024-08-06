import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:daily_flutter/daily_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class VapiEvent {
  final String label;
  final dynamic value;

  VapiEvent(this.label, [this.value]);
}

enum VapiAudioDevice {
  speakerphone,
  wired,
  earpiece,
  bluetooth,
}

class Vapi {
  final String publicKey;
  final String? apiBaseUrl;
  final _streamController = StreamController<VapiEvent>();

  Stream<VapiEvent> get onEvent => _streamController.stream;

  CallClient? _client;

  Vapi(this.publicKey, [this.apiBaseUrl]);

  Future<void> start({
    String? assistantId,
    dynamic assistant,
    dynamic assistantOverrides = const {},
    Duration clientCreationTimeoutDuration = const Duration(seconds: 10),
  }) async {
    if (_client != null) {
      throw Exception('Call already in progress');
    }

    print("🔄 ${DateTime.now()}: Vapi - Requesting Mic Permission...");
    var microphoneStatus = await Permission.microphone.request();
    if (microphoneStatus.isDenied) {
      microphoneStatus = await Permission.microphone.request();
      if (microphoneStatus.isPermanentlyDenied) {
        openAppSettings();
        return;
      }
    }

    print("🆗 ${DateTime.now()}: Vapi - Mic Permission Granted");

    if (assistantId == null && assistant == null) {
      throw ArgumentError('Either assistantId or assistant must be provided');
    }

    var baseUrl = '${apiBaseUrl ?? 'https://api.vapi.ai'}/call/web';
    var url = Uri.parse(baseUrl);
    var headers = {
      'Authorization': 'Bearer $publicKey',
      'Content-Type': 'application/json',
    };
    var body = assistantId != null
        ? jsonEncode({
            'assistantId': assistantId,
            'assistantOverrides': assistantOverrides
          })
        : jsonEncode(
            {'assistant': assistant, 'assistantOverrides': assistantOverrides});

    print("🔄 ${DateTime.now()}: Vapi - Preparing Call & Client...");

    // Create the Vapi call and client creation as futures
    var vapiCallFuture = http.post(url, headers: headers, body: body);
    var clientCreationFuture =
        _createClientWithRetries(clientCreationTimeoutDuration);

    // Wait for both futures to complete
    var results = await Future.wait([vapiCallFuture, clientCreationFuture]);

    var response = results[0] as http.Response;
    var client = results[1] as CallClient;

    _client = client;

    var webCallUrl = null;

    if (response.statusCode == 201) {
      print("🆗 ${DateTime.now()}: Vapi - Vapi Call Ready");

      var data = jsonDecode(response.body);
      webCallUrl = data['webCallUrl'];
      if (webCallUrl == null) {
        print('🆘 ${DateTime.now()}: Vapi - Vapi Call URL not found');
        emit(VapiEvent("call-error"));
        return;
      }
    } else {
      client.dispose();
      _client = null;
      print(
          '🆘 ${DateTime.now()}: Vapi - Failed to create Vapi Call. Error: ${response.body}');
      emit(VapiEvent("call-error"));
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

              emit(VapiEvent("call-end"));
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

    client
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
      throw Exception('🆘 ${DateTime.now()}: Vapi - Failed to join call: $e');
    });
  }

  Future<CallClient> _createClientWithRetries(
    Duration clientCreationTimeoutDuration,
  ) async {
    var retries = 0;
    const maxRetries = 5;

    Future<CallClient> attemptCreation() async {
      return CallClient.create();
    }

    Future<CallClient> createWithTimeout() async {
      var completer = Completer<CallClient>();
      Future.delayed(clientCreationTimeoutDuration).then((_) {
        if (!completer.isCompleted) {
          print("⏳ ${DateTime.now()}: Vapi - Client creation timed out.");
          completer
              .completeError(TimeoutException('Client creation timed out'));
        }
      });

      attemptCreation().then((client) {
        if (!completer.isCompleted) {
          completer.complete(client);
        }
      }).catchError((error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      });

      return completer.future;
    }

    while (retries < maxRetries) {
      try {
        print(
            "🔄 ${DateTime.now()}: Vapi - Creating client (Attempt ${retries + 1})...");
        var client = await createWithTimeout();
        print("🆗 ${DateTime.now()}: Vapi - Client Created");
        return client;
      } catch (e) {
        retries++;
        if (retries >= maxRetries) {
          print(
              "🆘 ${DateTime.now()}: Vapi - Failed to create client after $maxRetries attempts.");
          rethrow;
        }
      }
    }

    // This line should theoretically never be reached due to the rethrow above
    throw Exception('Client creation failed after $maxRetries retries');
  }

  Future<void> send(dynamic message) async {
    await _client!.sendAppMessage(jsonEncode(message), null);
  }

  void _onAppMessage(String msg) {
    try {
      var parsedMessage = jsonDecode(msg);

      if (parsedMessage == "listening") {
        print("✅ ${DateTime.now()}: Vapi - Assistant Connected.");
        emit(VapiEvent("call-start"));
      }

      emit(VapiEvent("message", parsedMessage));
    } catch (parseError) {
      print("Error parsing message data: $parseError");
    }
  }

  Future<void> stop() async {
    if (_client == null) {
      throw Exception('No call in progress');
    }
    await _client!.leave();
  }

  void setMuted(bool muted) {
    _client!.updateInputs(
        inputs: InputSettingsUpdate.set(
      microphone:
          MicrophoneInputSettingsUpdate.set(isEnabled: BoolUpdate.set(!muted)),
    ));
  }

  bool isMuted() {
    return _client!.inputs.microphone.isEnabled == false;
  }

  @Deprecated(
    "Use [setVapiAudioDevice] instead. Deprecated because unusable if user does not depend of daily_flutter",
  )

  /// use [setVapiAudioDevice] instead
  void setAudioDevice({required DeviceId deviceId}) {
    _client!.setAudioDevice(deviceId: deviceId);
  }

  void setVapiAudioDevice({required VapiAudioDevice device}) {
    _client!.setAudioDevice(
      deviceId: switch (device) {
        VapiAudioDevice.speakerphone => DeviceId.speakerPhone,
        VapiAudioDevice.wired => DeviceId.wired,
        VapiAudioDevice.earpiece => DeviceId.earpiece,
        VapiAudioDevice.bluetooth => DeviceId.bluetooth,
      },
    );
  }

  void emit(VapiEvent event) {
    _streamController.add(event);
  }

  void dispose() {
    _streamController.close();
  }
}
