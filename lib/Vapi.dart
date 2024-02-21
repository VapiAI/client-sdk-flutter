import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:daily_flutter/daily_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class Vapi {
  final String publicKey;
  final String? apiBaseUrl;

  CallClient? _client;

  Vapi(this.publicKey, this.apiBaseUrl);

  Future<void> startCall({String? assistantId, dynamic assistant}) async {
    var microphoneStatus = await Permission.microphone.request();
    print(microphoneStatus);
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
    print(response.statusCode);

    var webCallUrl = null;

    if (response.statusCode == 201) {
      var data = jsonDecode(response.body);
      webCallUrl = data['webCallUrl'];
    } else {
      throw Exception('Failed to make POST request');
    }

    if (webCallUrl == null) {
      throw Exception('No web call URL found in response');
    }
    print('Web call URL: $webCallUrl');

    var client = await CallClient.create();
    _client = client;

    client.events.listen((event) {
      print('Event: $event');
    });
    print('Joining call...');
    await client.join(
        url: Uri.parse(webCallUrl),
        clientSettings: const ClientSettingsUpdate.set(
            inputs: InputSettingsUpdate.set(
          microphone: MicrophoneInputSettingsUpdate.set(
              isEnabled: BoolUpdate.set(true)),
        )));

    print('Call joined');
    client.sendAppMessage(jsonEncode({'message': "playable"}), null);
  }

  Future<void> sendMessage(String role, String content) async {
    var message = {
      'type': 'add-message',
      'message': {
        'role': role,
        'content': content,
      },
    };
    await _client!.sendAppMessage(jsonEncode(message), null);
  }

  void onAppMessage(dynamic e) {
    if (e == null) return;
    try {
      if (e.data == "listening") {
        // emit("call-start");
      } else {
        try {
          var parsedMessage = jsonDecode(e.data);
          print("Parsed message: $parsedMessage");
          // emit("message", parsedMessage);
        } catch (parseError) {
          print("Error parsing message data: $parseError");
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> stopCall() async {
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
}
