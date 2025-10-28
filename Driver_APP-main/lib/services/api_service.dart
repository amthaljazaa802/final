import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // Allow overriding values for easier testing. If not provided, try reading from dotenv.
  final String? _overrideBaseUrl;
  final String? _overrideAuthToken;

  ApiService({String? baseUrl, String? authToken})
      : _overrideBaseUrl = baseUrl,
        _overrideAuthToken = authToken;

  String? get _baseUrl {
    if (_overrideBaseUrl != null) return _overrideBaseUrl;
    try {
      final envUrl = dotenv.env['API_BASE_URL'];
      if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    } catch (_) {}
    // Fallback to hardcoded value if .env not loaded
    return 'https://phenological-uncomplemented-jonie.ngrok-free.dev/api';
  }

  String? get _authToken {
    if (_overrideAuthToken != null) return _overrideAuthToken;
    try {
      final envToken = dotenv.env['AUTH_TOKEN'];
      if (envToken != null && envToken.isNotEmpty) return envToken;
    } catch (_) {}
    // Fallback to hardcoded value if .env not loaded
    return '666af57b6bbae376bd45f2abf487d6ae04b6e0b7';
  }

  // Accept an optional client for easier testing (defaults to new http.Client())
  Future<Map<String, dynamic>> getBusData(String busId, {http.Client? client}) async {
    if (_baseUrl == null || _authToken == null) {
      throw Exception('API configuration (URL or Token) is missing in .env file');
    }

    // Correct endpoint based on user-provided API documentation
    final url = Uri.parse('$_baseUrl/buses/$busId/');
    final headers = {
      'Authorization': 'Token $_authToken',
      'ngrok-skip-browser-warning': 'true',  // Required for ngrok to bypass browser warning
    };
    debugPrint('ApiService.getBusData -> GET $url');
    debugPrint('ApiService.getBusData -> headers: $headers');

    final usedClient = client ?? http.Client();
    try {
      final response = await usedClient.get(url, headers: headers);

      final responseBody = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        try {
          return jsonDecode(responseBody) as Map<String, dynamic>;
        } catch (e) {
          // Log full body (or truncated) to help debugging when server returns HTML/error page
          final snippet = responseBody.length > 1000
              ? responseBody.substring(0, 1000)
              : responseBody;
          debugPrint('ApiService.getBusData: Failed to parse JSON. Status: ${response.statusCode}. Body snippet:\n$snippet');
          throw Exception('Invalid JSON response from server: ${e.toString()}\nStatus: ${response.statusCode}\nBody starts with: ${responseBody.substring(0, min(200, responseBody.length))}');
        }
      } else {
        // Provide more details in the error log
        debugPrint('Error fetching bus data (status ${response.statusCode}): $responseBody');
        throw Exception('Failed to load bus data. Status code: ${response.statusCode}');
      }
    } finally {
      if (client == null) usedClient.close();
    }
  }

  Future<void> updateLocation(String busId, double latitude, double longitude, double speed, {http.Client? client}) async {
    if (_baseUrl == null || _authToken == null) {
      throw Exception('API configuration (URL or Token) is missing in .env file');
    }

    // Correct endpoint based on user-provided API documentation
    final url = Uri.parse('$_baseUrl/buses/$busId/update-location/');
    final headers = {
      'Authorization': 'Token $_authToken',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',  // Required for ngrok
    };
    final body = jsonEncode({
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'speed': speed.toString(),
    });

    final usedClient = client ?? http.Client();
    try {
      final response = await usedClient.post(url, headers: headers, body: body);

      // A successful POST might return 200 (OK) or 204 (No Content)
      if (response.statusCode != 200 && response.statusCode != 204) {
  // Provide more details in the error log
  debugPrint('Error updating location: ${response.body}');
        throw Exception('Failed to update location. Status code: ${response.statusCode}');
      }
    } finally {
      if (client == null) usedClient.close();
    }
  }
}
