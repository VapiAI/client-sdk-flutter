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

/// Thrown when attempting to start a call while another call is already in progress.
/// 
/// Only one call can be active at a time. Stop the current call before starting a new one.
class VapiCallInProgressException extends VapiException {
  /// Creates a new VapiCallInProgressException.
  const VapiCallInProgressException() : super('Call already in progress');
}

/// Thrown when neither assistantId nor assistant is provided to the start method.
/// 
/// At least one of these parameters must be provided to start a call:
/// - `assistantId`: ID of a pre-configured assistant
/// - `assistant`: Inline assistant configuration object
class VapiMissingAssistantException extends VapiException {
  /// Creates a new VapiMissingAssistantException.
  const VapiMissingAssistantException() : super('Either assistantId or assistant must be provided');
}

/// Thrown when the call client fails to join the call session.
/// 
/// This can happen due to network issues, invalid call URLs, or
/// other connectivity problems.
class VapiJoinFailedException extends VapiException {
  /// Creates a new VapiJoinFailedException with optional error [details].
  const VapiJoinFailedException([dynamic details]) : super('Failed to join call', details);
}

/// Thrown when call client creation times out.
/// 
/// This indicates that the Daily CallClient couldn't be created within
/// the specified timeout duration.
class VapiClientTimeoutException extends VapiException {
  /// Creates a new VapiClientTimeoutException.
  const VapiClientTimeoutException() : super('Client creation timed out');
}

/// Thrown when call client creation fails for reasons other than timeout.
/// 
/// This can happen due to missing dependencies, initialization errors,
/// or other system-level issues.
class VapiClientCreationFailedException extends VapiException {
  /// Creates a new VapiClientCreationFailedException with optional error [details].
  const VapiClientCreationFailedException([dynamic details]) : super('Failed to create client', details);
}

/// Thrown when call client creation fails after the maximum number of retry attempts.
/// 
/// This indicates persistent issues preventing client creation that
/// couldn't be resolved through retries.
class VapiMaxRetriesExceededException extends VapiException {
  /// Creates a new VapiMaxRetriesExceededException.
  const VapiMaxRetriesExceededException() : super('Client creation failed after maximum retries');
}

/// Thrown when attempting to perform an operation that requires an active call.
/// 
/// This exception is thrown when calling methods like [Vapi.send], [Vapi.stop],
/// [Vapi.setMuted], [Vapi.isMuted], or [Vapi.setVapiAudioDevice] without
/// an active call session.
class VapiNoCallException extends VapiException {
  /// Creates a new VapiNoCallException.
  const VapiNoCallException() : super('No call in progress');
} 