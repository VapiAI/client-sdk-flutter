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

  Vapi(this._callClient);

  Uri? _makeURL(required String path) {

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
    
    // Construct uri 
    return Uri(
      scheme: scheme, 
      host: host,
      port: port,
      path: path,
    );
  }

  Future<void> startCall(String roomUrl) async throws WebCallResponse {
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
  // int addOne(int value) => value + 1;
}
/* 
  1. makeUrl: line 203 reference
  2. makeUrlRequest: line 217 reference
  3. callDidFail: line 281 reference
  4. VapiError.customError: refer to method, VapiError, need equivalent for Swift.Error in dart
  5. WebCallResponse, refer to method, Decodable equivalent
  6. networkManager: refer to method, need URLSession equivalent, JSONDecoder equivalent
  7. joinCall: line 181 reference
*/