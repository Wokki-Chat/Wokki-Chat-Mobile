import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wokki_chat/config/app_config.dart';

class ApiService {
  static Future<Map<String, dynamic>> loginWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiUrl}/authorize'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'client_id': AppConfig.clientId,
        'response_type': 'token',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'access_token': data['access_token'],
        'refresh_token': data['refresh_token'] ?? '',
        'expires_in': data['expires_in'] ?? 3600,
      };
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Login failed');
    }
  }

  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiUrl}/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'client_id': AppConfig.clientId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {
        'access_token': data['access_token'],
        'refresh_token': data['refresh_token'] ?? '',
        'expires_in': data['expires_in'] ?? 3600,
      };
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Signup failed');
    }
  }

  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiUrl}/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': AppConfig.clientId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'access_token': data['access_token'],
        'refresh_token': data['refresh_token'] ?? refreshToken,
        'expires_in': data['expires_in'] ?? 3600,
      };
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Token refresh failed');
    }
  }

  static Future<dynamic> authenticatedRequest({
    required String endpoint,
    required String method,
    required String accessToken,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${AppConfig.apiUrl}$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'PUT':
        response = await http.put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - token may be expired');
    } else {
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Request failed');
      } catch (_) {
        throw Exception('Request failed with status ${response.statusCode}');
      }
    }
  }
}