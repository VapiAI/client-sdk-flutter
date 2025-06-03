import 'dart:js_interop';

/// Extension type wrapper for the JavaScript Vapi instance 
/// 
/// This provides Dart bindings for the @vapi-ai/web package
@JS("VapiEsModule.default")
extension type VapiJs._(JSObject _) implements JSObject {
  /// Creates a new Vapi instance
  external factory VapiJs(String apiKey, [JSAny? apiBaseUrl]);

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

  /// Set the output device
  external JSPromise<JSAny?> setOutputDeviceAsync(JSAny options);

  /// Set the input device
  external JSPromise<JSAny?> setInputDeviceAsync(JSAny options);
}
