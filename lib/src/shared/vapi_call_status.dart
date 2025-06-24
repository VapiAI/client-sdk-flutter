/// Represents the current status of a Vapi call.
/// 
/// The call progresses through these states:
/// - [starting]: Call is being initialized and connecting
/// - [active]: Call is connected and ready for interaction
/// - [ended]: Call has been terminated or disconnected
enum VapiCallStatus {
  /// Call is being initialized and connecting to the assistant.
  starting,
  
  /// Call is connected and ready for interaction with the assistant.
  active,
  
  /// Call has been terminated or disconnected.
  ended,
} 
