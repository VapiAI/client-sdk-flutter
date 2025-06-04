/// Represents the transport configuration for a Vapi call.
/// 
/// Contains information about the call transport provider and settings.
class VapiCallTransport {
  /// The transport provider (e.g., "daily").
  final String provider;
  
  /// Whether assistant video is enabled for this call.
  final bool assistantVideoEnabled;
  
  /// The call URL for the transport provider.
  final String callUrl;

  /// Creates a VapiCallTransport instance.
  const VapiCallTransport({
    required this.provider,
    required this.assistantVideoEnabled,
    required this.callUrl,
  });

  /// Creates a VapiCallTransport from a JSON object.
  factory VapiCallTransport.fromJson(Map<String, dynamic> json) {
    return VapiCallTransport(
      provider: json['provider'],
      assistantVideoEnabled: json['assistantVideoEnabled'],
      callUrl: json['callUrl'],
    );
  }
}