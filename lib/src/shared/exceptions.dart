/// Base exception class for all Vapi-related errors.
/// 
/// This exception provides a consistent interface for handling errors
/// that occur during Vapi operations.
class VapiException implements Exception {
  /// A human-readable description of the error.
  final String message;
  
  /// Optional additional details about the error.
  /// 
  /// This field may contain error objects, stack traces, or other
  /// debugging information depending on the specific error type.
  final dynamic details;

  /// Creates a new VapiException with the given [message] and optional [details].
  const VapiException(this.message, [this.details]);

  @override
  String toString() => 'VapiException: $message${details != null ? '\nDetails: $details' : ''}';
}

/// Thrown when neither assistantId nor assistant is provided to the start method.
/// 
/// At least one of these parameters must be provided to start a call:
/// - `assistantId`: ID of a pre-configured assistant
/// - `assistant`: Inline assistant configuration object
class VapiMissingAssistantException extends VapiException {
  const VapiMissingAssistantException() : super('Either assistantId or assistant must be provided');
}

/// Thrown when the client is configured with invalid parameters.
/// 
/// This includes cases like empty public keys, invalid URLs, or
/// other configuration errors that prevent proper operation.
class VapiConfigurationException extends VapiException {
  const VapiConfigurationException(String message) : super(message);
}

/// Thrown when the call client fails to start or join the call session.
/// 
/// This can happen due to network issues, invalid call URLs, or
/// other connectivity problems.
class VapiStartCallException extends VapiException {
  const VapiStartCallException([dynamic details]) : super('Failed to start call', details);
}

/// Thrown when attempting to start a call while another call is already in progress.
/// 
/// Only one call can be active at a time. Stop the current call before starting a new one.
class VapiCallInProgressException extends VapiException {
  const VapiCallInProgressException() : super('Call already in progress');
}

/// Thrown when attempting to perform an operation on a call that has ended.
/// 
/// This exception is thrown when calling methods like [VapiCall.send], [VapiCall.stop],
/// [VapiCall.setMuted], [VapiCall.isMuted], or [VapiCall.setVapiAudioDevice] on
/// a call that is no longer active.
class VapiCallEndedException extends VapiException {
  const VapiCallEndedException() : super('Call has ended');
} 
