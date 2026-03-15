import 'dart:convert';
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
            .post(
              Uri.parse('$base$path'),
              headers: headers,
              body: body,
            )
            .timeout(const Duration(seconds: 10));
        return response;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }
    throw lastError ?? Exception('All endpoints unreachable');
  }

  static Future<http.Response> _getWithFallback({
    required String path,
    required Map<String, String> headers,
  }) async {
    Exception? lastError;
    for (final base in _baseUrls) {
      try {
        final response = await http
            .get(Uri.parse('$base$path'), headers: headers)
            .timeout(const Duration(seconds: 10));
        return response;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }
    throw lastError ?? Exception('All endpoints unreachable');
  }

  static Future<String?> _ensureValidToken(AuthService authService) async {
    final accessToken = await authService.getAccessToken();
    if (accessToken == null) return null;

    if (await authService.isAccessTokenValid()) {
      return accessToken;
    }

    final refreshTokenValue = await authService.getRefreshToken();
    if (refreshTokenValue == null || refreshTokenValue.isEmpty) {
      return null;
    }

    try {
      final response = await ApiService.refreshToken(refreshTokenValue);
      await authService.saveTokens(
        accessToken: response['access_token'],
        refreshToken: response['refresh_token'],
      );
      return response['access_token'];
    } catch (_) {
      return null;
    }
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
            .post(
              Uri.parse('$base/signup'),
              headers: headers,
              body: body,
            )
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

  static Future<Map<String, dynamic>> refreshToken(
      String refreshToken) async {
    final body = jsonEncode({
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
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
        'refresh_token': data['refresh_token'] ?? refreshToken,
        'expires_in': data['expires_in'] ?? 3600,
      };
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
          error['error_description'] ?? 'Token refresh failed');
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
      validToken = await _ensureValidToken(authService);
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