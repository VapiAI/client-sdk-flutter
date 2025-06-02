/// Vapi Flutter SDK with unified mobile and web support
/// 
/// A Flutter SDK for integrating with the Vapi voice AI platform.
/// 
/// This library provides a simple and intuitive interface for adding
/// voice AI capabilities to your Flutter applications across multiple platforms.
/// 
/// ## Getting Started
/// 
/// 1. Create a VapiClient instance with your public API key:
/// ```dart
/// final vapiClient = VapiClient('your-public-key-here');
/// ```
/// 
/// 2. Start a call and get a VapiCall instance:
/// ```dart
/// final call = await vapiClient.start(assistantId: 'your-assistant-id');
/// ```
/// 
/// 3. Access call information:
/// ```dart
/// print('Call ID: ${call.id}');
/// print('Assistant ID: ${call.assistantId}');
/// print('Created at: ${call.createdAt}');
/// print('Status: ${call.status}');
/// ```
/// 
/// 4. Listen for events on the call:
/// ```dart
/// call.onEvent.listen((event) {
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
/// 5. Interact during the call:
/// ```dart
/// // Send a message
/// await call.send({'type': 'user-message', 'message': 'Hello'});
/// 
/// // Mute/unmute
/// call.setMuted(true);
/// 
/// // Change audio device (mobile only)
/// if (call is VapiMobileCall) {
///   call.setAudioDevice(device: VapiAudioDevice.speakerphone);
/// }
/// 
/// // Check if call is still active
/// if (call.status == VapiCallStatus.active) {
///   // Call is still ongoing
/// }
/// ```
/// 
/// 6. End the call and clean up:
/// ```dart
/// await call.stop();
/// call.dispose();
/// client.dispose();
/// ```
/// 
/// ## Architecture
/// 
/// The SDK uses a clean factory pattern with platform-specific implementations:
/// 
/// - **VapiClient**: Factory class that creates platform-appropriate implementations
/// - **VapiClientInterface**: Abstract interface for all client implementations
/// - **VapiCallInterface**: Abstract interface for all call implementations
/// - **VapiMobileClient/VapiMobileCall**: Mobile implementation using Daily.co WebRTC
/// - **VapiWebClient/VapiWebCall**: Web implementation using Vapi Web SDK (coming soon)
/// 
/// This architecture allows for:
/// - Automatic platform detection and selection
/// - Platform-specific optimizations
/// - Clean separation of concerns
/// - Easy addition of new platforms
/// - Type-safe platform-specific features
/// - Consistent API across platforms
/// 
/// ## Available Types
/// 
/// The SDK exports the following types for your use:
/// - [VapiClient] - The main factory class for creating platform-appropriate clients
/// - [VapiClientInterface] - Interface for client implementations
/// - [VapiCallInterface] - Interface for call implementations
/// - [VapiCallStatus] - Enum representing call status (starting, active, ended)
/// - [VapiEvent] - Event objects emitted during calls
/// - [VapiAudioDevice] - Audio device options
/// - Various exception classes for error handling
library vapi;

// Export the main factory client class (conditional based on platform)
export 'src/vapi_client.dart';

// Export the interfaces for type checking
export 'src/vapi_client_interface.dart';
export 'src/vapi_call_interface.dart';

// Export all types
export 'src/types/types.dart'; 