/// The base error class for all Vapi-related errors.
///
/// This class is used to represent errors that are related to the Vapi SDK itself,
/// such as programming mistakes or violations of SDK contracts. These are not
/// exceptions caused by user actions or runtime failures, but rather indicate
/// that something is wrong in the SDK usage or implementation.
///
/// Prefer using [VapiError] for errors that are not expected to be caught during
/// normal execution, and that indicate a bug or misconfiguration in the code.
/// For recoverable or user-caused issues, use exceptions instead.
class VapiError extends Error {
  /// A human-readable message describing the error.
  final String message;

  /// Optional additional details about the error.
  final dynamic details;

  /// Creates a new [VapiError] with the given [message] and optional [details].
  VapiError(this.message, [this.details]);

  @override
  String toString() {
    if (details != null) {
      return 'VapiError: $message - Details: $details';
    }
    return 'VapiError: $message';
  }
}

/// Error thrown when the Vapi client cannot be created 
///
/// This is most likely due to platform specific issues
class VapiClientCreationError extends VapiError {
  VapiClientCreationError(super.message, [super.details]);
}
