class VapiError implements Exception {
    final String message;
    final String? response;

    VapiError._(this.message, [this.response]);

    factory VapiError.invalidURL() => VapiError._("Invalid URL");
    factory VapiError.customError(String message) => VapiError._(message);
    factory VapiError.existingCallInProgress() => VapiError._("Existing call in progress.");
    factory VapiError.noCallInProgress() => VapiError._("No call in progress.");
    factory VapiError.decodingError({required String message, String? response}) => VapiError._(message, response);
    factory VapiError.invalidJsonData() => VapiError._("Invalid JSON data.");
    factory VapiError.networkError(String response) => VapiError._("Network error", response);

    @override
    String toString() => message + (response != null ? " Response: $response" : "");
}