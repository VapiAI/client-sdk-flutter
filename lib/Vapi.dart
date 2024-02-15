library vapi;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:daily_flutter/daily_flutter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'models/exports/Exports.dart';

class Vapi {
  late final CallClient _callClient;

  Vapi() {
    _callClient = Daily().createCallClient(); 
  }

  Future<void> startCall(String roomUrl) async {
    try {
      await _callClient.join(CallJoinData(url: roomUrl));
    } catch (e) {
      print("Error starting call: $e");
    }
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