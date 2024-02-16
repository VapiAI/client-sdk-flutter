class Configuration {
    final String host;
    final String publicKey;
    static const String defaultHost = "api.vapi.ai";

    Configuration({required this.publicKey, String host = defaultHost})
        : this.host = host;
}