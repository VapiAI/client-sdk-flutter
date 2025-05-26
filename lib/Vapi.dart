/// Vapi Flutter SDK
/// 
/// A Flutter SDK for integrating with the Vapi voice AI platform.
/// 
/// This library provides a simple and intuitive interface for adding
/// voice AI capabilities to your Flutter applications.
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
/// print('Monitor listen URL: ${call.monitor.listenUrl}');
/// print('Transport provider: ${call.transport.provider}');
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
/// // Change audio device
/// call.setVapiAudioDevice(device: VapiAudioDevice.speakerphone);
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
/// ```
/// 
/// ## Architecture
/// 
/// The SDK uses a clean separation of concerns:
/// 
/// - **VapiClient**: Handles client configuration, authentication, and call creation
/// - **VapiCall**: Manages individual call sessions with their own state and lifecycle
/// - **VapiCallMonitor**: Contains monitoring URLs for call observation and control
/// - **VapiCallTransport**: Contains transport provider configuration and settings
/// 
/// This architecture allows for:
/// - Better resource management (each call manages its own resources)
/// - Cleaner error handling (call-specific vs client-specific errors)
/// - Potential for multiple concurrent calls in future versions
/// - More intuitive API where operations are performed on call instances
/// - Rich call metadata access for monitoring and debugging
/// 
/// ## Available Types
/// 
/// The SDK exports the following types for your use:
/// - [VapiClient] - The main client class for creating calls
/// - [VapiCall] - Individual call instance for managing active calls
/// - [VapiCallMonitor] - Monitor configuration with listen and control URLs
/// - [VapiCallTransport] - Transport configuration and provider settings
/// - [VapiCallStatus] - Enum representing call status (starting, active, ended)
/// - [VapiEvent] - Event objects emitted during calls
/// - [VapiAudioDevice] - Audio device options
/// - Various exception classes for error handling
library vapi;

// Export the main Vapi client and call classes
export 'src/vapi_client.dart' show VapiClient;
export 'src/vapi_call.dart' show VapiCall, VapiCallMonitor, VapiCallTransport;

// Export all types
export 'src/types/types.dart'; 