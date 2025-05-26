/// Vapi Flutter SDK
/// 
/// A Flutter SDK for integrating with the Vapi voice AI platform.
/// 
/// This library provides a simple and intuitive interface for adding
/// voice AI capabilities to your Flutter applications.
/// 
/// ## Getting Started
/// 
/// 1. Create a Vapi instance with your public API key:
/// ```dart
/// final vapi = Vapi('your-public-key-here');
/// ```
/// 
/// 2. Listen for events:
/// ```dart
/// vapi.onEvent.listen((event) {
///   switch (event.label) {
///     case 'call-start':
///       print('Assistant is ready and listening');
///       break;
///     case 'call-end':
///       print('Call has ended');
///       break;
///     case 'message':
///       print('Message from assistant: ${event.value}');
///       break;
///   }
/// });
/// ```
/// 
/// 3. Start a call:
/// ```dart
/// await vapi.start(assistantId: 'your-assistant-id');
/// ```
/// 
/// 4. Interact during the call:
/// ```dart
/// // Send a message
/// await vapi.send({'type': 'user-message', 'message': 'Hello'});
/// 
/// // Mute/unmute
/// vapi.setMuted(true);
/// 
/// // Change audio device
/// vapi.setVapiAudioDevice(device: VapiAudioDevice.speakerphone);
/// ```
/// 
/// 5. End the call and clean up:
/// ```dart
/// await vapi.stop();
/// vapi.dispose();
/// ```
/// 
/// ## Available Types
/// 
/// The SDK exports the following types for your use:
/// - [Vapi] - The main client class
/// - [VapiEvent] - Event objects emitted during calls
/// - [VapiAudioDevice] - Audio device options
/// - Various exception classes for error handling
library vapi;

// Export the main Vapi client
export 'src/vapi_impl.dart' show Vapi;

// Export all types
export 'src/types/types.dart'; 