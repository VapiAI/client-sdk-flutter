/// Represents an event that occurs during the Vapi call lifecycle.
/// 
/// Events are emitted by the Vapi client to inform your application
/// about important state changes and messages during a call.
/// 
/// Common event types include:
/// - `call-start`: Emitted when the assistant connects and starts listening
/// - `call-end`: Emitted when the call ends
/// - `call-error`: Emitted when an error occurs during call setup
/// - `message`: Emitted when a message is received from the assistant
/// 
/// Example usage:
/// ```dart
/// vapi.onEvent.listen((event) {
///   switch (event.label) {
///     case 'call-start':
///       print('Call started');
///       break;
///     case 'call-end':
///       print('Call ended');
///       break;
///     case 'message':
///       print('Received message: ${event.value}');
///       break;
///   }
/// });
/// ```
class VapiEvent {
  /// The type/label of the event that occurred.
  /// 
  /// This string identifies what kind of event happened and helps
  /// your application respond appropriately.
  final String label;
  
  /// Optional data associated with the event.
  /// 
  /// The type and structure of this value depends on the event type:
  /// - For `message` events, this contains the parsed message data
  /// - For error events, this may contain error details
  /// - For lifecycle events like `call-start` and `call-end`, this is typically null
  final dynamic value;

  /// Creates a new VapiEvent with the specified [label] and optional [value].
  const VapiEvent(this.label, [this.value]);
} 