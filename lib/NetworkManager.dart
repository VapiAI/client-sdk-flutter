import 'dart:convert';
import 'package:http/http.dart';

class NetworkManager {
    Future<T> perform<T>(http.Request request, T Function(Map<String, dynamic>) fromJson) async {
        final response = await http.Client().send(request);
        final responseBody = await response.stream.bytesToString(); 

        if (response.statusCode == 200) {
            try {
                final decodedJson = jsonDecode(responseBody) as Map<String, dynamic>;
                return fromJson(decodedJson);
            } catch (e) {
                throw VapiError.decodingError(message: e.toString(), response: responseBody);
            } else {
                throw VapiError.networkError(responseBody); // Implement VapiError, implements Exception
            }
        }
    }
}