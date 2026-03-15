import 'dart:convert';
import 'dart:developer' as developer;
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:wokki_chat/config/app_config.dart';
import 'package:wokki_chat/services/device_service.dart';
import 'package:wokki_chat/services/auth_service.dart';

class ApiService {
  static List<String> get _baseUrls {
    final urls = [AppConfig.apiUrl];
    if (AppConfig.apiUrlFallback.isNotEmpty) {
      urls.add(AppConfig.apiUrlFallback);
    }
    return urls;
  }

  static Future<Map<String, String>> _signedHeaders(String body) async {
    final deviceId = await DeviceService.getDeviceId();
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final message = '$timestamp.$deviceId.$body';
    final hmac = Hmac(sha256, utf8.encode(AppConfig.hmacSecret));
    final signature = hmac.convert(utf8.encode(message)).toString();
    return {
      'Content-Type': 'application/json',
      'X-App-Timestamp': timestamp,
      'X-App-Signature': signature,
      'X-Device-ID': deviceId,
    };
  }

  static Future<http.Response> _postWithFallback({
    required String path,
    required Map<String, String> headers,
    required String body,
  }) async {
    Exception? lastError;
    for (final base in _baseUrls) {
      try {
        final response = await http
            .post(Uri.parse('$base$path'), headers: headers, body: body)
            .timeout(const Duration(seconds: 10));
        return response;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }
    throw lastError ?? Exception('All endpoints unreachable');
  }

  static Future<Map<String, dynamic>> loginWithPassword({
    required String email,
    required String password,
  }) async {
    final body = jsonEncode({
      'grant_type': 'password',
      'email': email,
      'password': password,
      'client_id': AppConfig.clientId,
    });

    final response = await _postWithFallback(
      path: '/mobile_token',
      headers: await _signedHeaders(body),
      body: body,
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
      throw Exception(error['error_description'] ?? 'Login failed');
    }
  }

  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final body = jsonEncode({
      'name': name,
      'email': email,
      'password': password,
      'client_id': AppConfig.clientId,
    });

    final headers = {'Content-Type': 'application/json'};

    Exception? lastError;
    for (final base in _baseUrls) {
      try {
        final response = await http
            .post(Uri.parse('$base/signup'), headers: headers, body: body)
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return {
            'access_token': data['access_token'],
            'refresh_token': data['refresh_token'] ?? '',
            'expires_in': data['expires_in'] ?? 3600,
          };
        } else {
          final error = jsonDecode(response.body);
          throw Exception(
              error['error_description'] ?? error['message'] ?? 'Signup failed');
        }
      } on Exception catch (e) {
        if (e.toString().contains('Signup failed') ||
            e.toString().contains('error_description')) {
          rethrow;
        }
        lastError = e;
      }
    }
    throw lastError ?? Exception('All endpoints unreachable');
  }

  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    developer.log('[TOKEN] Sending refresh_token grant to /mobile_token', name: 'ApiService');

    final body = jsonEncode({
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
      'client_id': AppConfig.clientId,
    });

    http.Response response;
    try {
      response = await _postWithFallback(
        path: '/mobile_token',
        headers: await _signedHeaders(body),
        body: body,
      );
    } catch (e) {
      developer.log('[TOKEN] Network error during refresh: $e', name: 'ApiService');
      rethrow;
    }

    developer.log('[TOKEN] Refresh response status: ${response.statusCode}', name: 'ApiService');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final hasAccess = data['access_token'] != null &&
          (data['access_token'] as String).isNotEmpty;
      final hasRefresh = data['refresh_token'] != null &&
          (data['refresh_token'] as String).isNotEmpty;
      developer.log(
        '[TOKEN] Refresh OK — access_token: ${hasAccess ? "present" : "MISSING"}, refresh_token: ${hasRefresh ? "present" : "not returned"}',
        name: 'ApiService',
      );
      return {
        'access_token': data['access_token'],
        'refresh_token': data['refresh_token'] ?? refreshToken,
        'expires_in': data['expires_in'] ?? 3600,
      };
    } else {
      final rawBody = response.body;
      developer.log(
          '[TOKEN] Refresh FAILED — status ${response.statusCode}, body: $rawBody',
          name: 'ApiService');
      Map<String, dynamic>? error;
      try {
        error = jsonDecode(rawBody);
      } catch (_) {}
      throw Exception(error?['error_description'] ??
          'Token refresh failed (${response.statusCode})');
    }
  }

  static Future<dynamic> authenticatedRequest({
    required String endpoint,
    required String method,
    required String accessToken,
    Map<String, dynamic>? body,
    AuthService? authService,
  }) async {
    String? validToken = accessToken;

    if (authService != null) {
      validToken = await authService.ensureValidToken(ApiService.refreshToken);
      if (validToken == null) {
        throw Exception('Session expired - please log in again');
      }
    }

    final deviceId = await DeviceService.getDeviceId();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $validToken',
      'X-Device-ID': deviceId,
    };

    Exception? lastError;

    for (final base in _baseUrls) {
      final uri = Uri.parse('$base$endpoint');
      try {
        http.Response response;
        switch (method.toUpperCase()) {
          case 'GET':
            response = await http
                .get(uri, headers: headers)
                .timeout(const Duration(seconds: 10));
            break;
          case 'POST':
            response = await http
                .post(uri,
                    headers: headers,
                    body: body != null ? jsonEncode(body) : null)
                .timeout(const Duration(seconds: 10));
            break;
          case 'PUT':
            response = await http
                .put(uri,
                    headers: headers,
                    body: body != null ? jsonEncode(body) : null)
                .timeout(const Duration(seconds: 10));
            break;
          case 'DELETE':
            response = await http
                .delete(uri, headers: headers)
                .timeout(const Duration(seconds: 10));
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
            throw Exception(error['error_description'] ??
                error['message'] ??
                'Request failed');
          } catch (_) {
            throw Exception(
                'Request failed with status ${response.statusCode}');
          }
        }
      } on Exception catch (e) {
        if (e.toString().contains('Unauthorized') ||
            e.toString().contains('Unsupported HTTP method') ||
            e.toString().contains('Session expired')) {
          rethrow;
        }
        lastError = e;
      }
    }

    throw lastError ?? Exception('All endpoints unreachable');
  }
}