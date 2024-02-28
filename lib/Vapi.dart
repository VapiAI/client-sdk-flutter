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

class Vapi {
  final String publicKey;
  final String? apiBaseUrl;
  final _streamController = StreamController<VapiEvent>();

  Stream<VapiEvent> get onEvent => _streamController.stream;

  CallClient? _client;

  Vapi(this.publicKey, [this.apiBaseUrl]);

  Future<void> start({String? assistantId, dynamic assistant}) async {
    if (_client != null) {
      throw Exception('Call already in progress');
    }

    var microphoneStatus = await Permission.microphone.request();
    if (microphoneStatus.isDenied) {
      microphoneStatus = await Permission.microphone.request();
      if (microphoneStatus.isPermanentlyDenied) {
        openAppSettings();
        return;
      }
    }

    if (assistantId == null && assistant == null) {
      throw ArgumentError('Either assistantId or assistant must be provided');
    }

    var url = Uri.parse('https://api.vapi.ai/call/web');
    var headers = {
      'Authorization': 'Bearer $publicKey',
      'Content-Type': 'application/json',
    };
    var body = assistantId != null
        ? jsonEncode({'assistantId': assistantId})
        : jsonEncode({'assistant': assistant});

    var response = await http.post(url, headers: headers, body: body);

    var webCallUrl = null;

    if (response.statusCode == 201) {
      var data = jsonDecode(response.body);
      webCallUrl = data['webCallUrl'];
    } else {
      throw Exception('Failed to make POST request. Error: ${response.body}');
    }

    if (webCallUrl == null) {
      throw Exception('No web call URL found in response');
    }

    var client = await CallClient.create();
    _client = client;

    print('Joining call...');

    client.events.listen((event) {
      event.whenOrNull(
        callStateUpdated: (stateData) {
          if (stateData.state == CallState.leaving ||
              stateData.state == CallState.left) {
            _client?.dispose();
            _client = null;
            emit(VapiEvent("call-end"));
          }
        },
        appMessageReceived: (messageData, id) {
          _onAppMessage(messageData);
        },
      );
    });

    client.setAudioDevice(deviceId: DeviceId.speakerPhone);

    try {
      await client.join(
          url: Uri.parse(webCallUrl),
          clientSettings: const ClientSettingsUpdate.set(
              inputs: InputSettingsUpdate.set(
            microphone: MicrophoneInputSettingsUpdate.set(
                isEnabled: BoolUpdate.set(true)),
            camera:
                CameraInputSettingsUpdate.set(isEnabled: BoolUpdate.set(false)),
          )));
    } catch (e) {
      throw Exception('Failed to join call: $e');
    }

    client.sendAppMessage(jsonEncode({'message': "playable"}), null);

    emit(VapiEvent("call-start"));
  }

  Future<void> send(dynamic message) async {
    await _client!.sendAppMessage(jsonEncode(message), null);
  }

  void _onAppMessage(String msg) {
    try {
      if (msg == "listening") {
      } else {
        try {
          var parsedMessage = jsonDecode(msg);

          emit(VapiEvent("message", parsedMessage));
        } catch (parseError) {
          print("Error parsing message data: $parseError");
        }
      }
    } catch (e) {
      print(e);
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

  void emit(VapiEvent event) {
    _streamController.add(event);
  }

  void dispose() {
    _streamController.close();
  }
}
