library vapi;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:daily_flutter/daily_flutter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'models/exports/Exports.dart';

class Vapi {
  int addOne(int value) => value + 1;
}