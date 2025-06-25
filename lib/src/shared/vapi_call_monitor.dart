/// Represents the monitor configuration for a Vapi call.
///
/// Contains URLs for monitoring and controlling the call.
class VapiCallMonitor {
  /// WebSocket URL for listening to call events.
  final String listenUrl;

  /// HTTP URL for controlling the call.
  final String controlUrl;

  /// Creates a VapiCallMonitor instance.
  const VapiCallMonitor({
    required this.listenUrl,
    required this.controlUrl,
  });

  /// Creates a VapiCallMonitor from a JSON object.
  factory VapiCallMonitor.fromJson(Map<String, dynamic> json) {
    return VapiCallMonitor(
      listenUrl: json['listenUrl'],
      controlUrl: json['controlUrl'],
    );
  }
}
