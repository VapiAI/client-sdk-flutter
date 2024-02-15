library vapi;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:daily_flutter/daily_flutter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'models/exports/Exports.dart';

class Vapi {
  final CallClient _callClient;
  final Configuration configuration;

  final StreamController _eventSubject = StreamController.broadcast(); 

  _networkManager = NetworkManager(); 
  
  class Configuration {
    final String host;
    final String publicKey;

    Configuration({required this.publicKey, String host = defaultHost})
        : this.host = host;

    Map<String, dynamic> toJson() => {
      'host': host,
      'publicKey': publicKey
    };

    factory Configuration.fromJson(Map<String, dynamic> json) => Configuration(
      publicKey: json['publicKey'],
      host: json['host'] ?? defaultHost,
    );
  }

  Vapi(this._callClient);

  Uri? _makeURL(String path) {

    const String endpoint = "/call/web";
    if (!path.endsWith(endpoint)) {
      path = "$path$endpoint"; // Append "/call/web" if not present
    }

    String scheme = 'https';
    int? port;

    if (configuration.host == "localhost") {
      scheme = 'http'; 
      port = 3001; 
    }

    return Uri(
      scheme: scheme, 
      host: host,
      port: port,
      path: path,
    );
  }

  Future<http.Response> makeUrlRequest(Uri url) async {
    var headers = {
      'Authorization': 'Bearer $publicKey',
      'Content-Type': 'application/json',
    };

    // Send POST
    var response = await http.post(url, headers);
    return response;
  }

  Future<void> startCall(String roomUrl) async /* throws WebCallResponse : implement */ {
    Uri? callUrl = makeURL(path: path) else {
      callDidFail(with: VapiError.invalidURL) // need to implement callDidFail, VapiError.invalidURL works I think
      throw VapiError.customError("Unable to create web call")
    }
    try {
      await _callClient.join(CallJoinData(url: roomUrl));
    } catch (e) {
      print("Error starting call: $e");
    }

    var request = makeUrlRequest(for: url); 
  }  
  
  void callDidFail(Exception error) {
    print("Got error while joining/leaving call: $error.");

    _eventSubject.addError(error);
    call = null;
  }

  void eventSubjectDispose() {
    _eventSubject.close();
  }
}

class DidCompile {
  int addOne(int value) => value + 1;
}
/* 
  1. makeUrl: line 203 reference - Done
  2. makeUrlRequest: line 217 reference - Done
  3. callDidFail: line 281 reference - Done 
  4. VapiError.customError: refer to method, VapiError, need equivalent for Swift.Error in dart - Looks good, check to make sure it's equivalent to swift
  5. WebCallResponse, refer to method, Decodable equivalent - Looks good, check back as other methods are built
  6. networkManager: refer to method, need URLSession equivalent, JSONDecoder equivalent
  7. joinCall: line 181 reference

  Check for errors, compile periodically
*/