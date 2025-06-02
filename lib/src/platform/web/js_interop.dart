@JS()
library vapi_web_interop;

import 'dart:js_interop';

/// JavaScript interop for the Vapi Web SDK using latest dart:js_interop.
/// 
/// This provides Dart bindings for the @vapi-ai/web package,
/// using modern extension types and avoiding deprecated APIs.

/// JavaScript Vapi class from @vapi-ai/web
@JS('Vapi')
external JSFunction get _VapiConstructor;

/// JavaScript Object.keys function
@JS('Object.keys')
external JSArray<JSString> _objectKeys(JSObject object);

/// Extension type wrapper for the JavaScript Vapi instance
extension type VapiJS._(JSObject _) implements JSObject {
  /// Creates a new Vapi instance
  external VapiJS(String publicKey);

  /// Start a call with assistant configuration
  external JSPromise<JSObject> start(JSAny assistantConfig, [JSObject? overrides]);

  /// Stop the current call
  external void stop();

  /// Send a message during the call
  external void send(JSObject message);

  /// Check if microphone is muted
  external bool isMuted();

  /// Set microphone mute state
  external void setMuted(bool muted);

  /// Make the assistant say something
  external void say(String message, [bool? endCallAfterSpoken]);

  /// Add event listener
  external void on(String event, JSFunction callback);
}

/// Extension methods for JSObject property access
extension JSObjectExtension on JSObject {
  external JSAny? operator [](JSAny key);
  external void operator []=(JSAny key, JSAny? value);
}

/// Utility functions for JavaScript interop

/// Convert a Dart Map to a JavaScript Object
JSObject dartMapToJS(Map<String, dynamic> dartMap) {
  final jsObject = JSObject();
  dartMap.forEach((key, value) {
    jsObject[key.toJS] = _convertDartToJS(value);
  });
  return jsObject;
}

/// Convert a JavaScript Object to a Dart Map
Map<String, dynamic> jsObjectToDartMap(JSObject jsObject) {
  final result = <String, dynamic>{};
  final keys = _objectKeys(jsObject);
  
  for (int i = 0; i < keys.length; i++) {
    final key = keys[i].toDart;
    final value = jsObject[key.toJS];
    result[key] = _convertJSToDart(value);
  }
  
  return result;
}

/// Convert Dart values to JavaScript equivalents
JSAny? _convertDartToJS(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.toJS;
  if (value is num) return value.toJS;
  if (value is bool) return value.toJS;
  if (value is List) {
    return value.map(_convertDartToJS).toList().toJS;
  }
  if (value is Map<String, dynamic>) {
    return dartMapToJS(value);
  }
  return value.toString().toJS;
}

/// Convert JavaScript values to Dart equivalents
dynamic _convertJSToDart(JSAny? value) {
  if (value == null) return null;
  if (value.isA<JSString>()) return (value as JSString).toDart;
  if (value.isA<JSNumber>()) return (value as JSNumber).toDartDouble;
  if (value.isA<JSBoolean>()) return (value as JSBoolean).toDart;
  if (value.isA<JSArray>()) {
    final array = value as JSArray;
    return List.generate(array.length, (i) => _convertJSToDart(array[i]));
  }
  if (value.isA<JSObject>()) {
    return jsObjectToDartMap(value as JSObject);
  }
  return value.toString();
} 