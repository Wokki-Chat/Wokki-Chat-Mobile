import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:wokki_chat/config/app_config.dart';
import 'package:wokki_chat/models/user_model.dart';
import 'package:wokki_chat/services/device_service.dart';

class UserService {
  static UserModel? _cachedUser;

  static UserModel? get cachedUser => _cachedUser;

  static void clearCache() {
    _cachedUser = null;
  }

  static void _log(String message) {
    developer.log(message, name: 'UserService');
    print('[UserService] $message');
  }

  static Future<UserModel> fetchMyProfile(String accessToken) async {
    final deviceId = await DeviceService.getDeviceId();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
      'X-Device-ID': deviceId,
    };

    final urls = [
      '${AppConfig.apiUrl}/me/profile',
      if (AppConfig.apiUrlFallback.isNotEmpty)
        '${AppConfig.apiUrlFallback}/me/profile',
    ];

    _log('Starting profile fetch. Trying ${urls.length} endpoint(s).');

    Exception? lastError;

    for (int i = 0; i < urls.length; i++) {
      final url = urls[i];
      _log('[${i + 1}/${urls.length}] GET $url');

      try {
        final response = await http
            .get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 10));

        _log('Response status: ${response.statusCode}');
        _log('Response body: ${response.body}');

        if (response.statusCode == 200) {
          final body = response.body.trim();
          final lines =
              body.split('\n').where((l) => l.trim().isNotEmpty).toList();

          _log('Parsed ${lines.length} line(s) from response body.');

          Map<String, dynamic>? userData;

          for (int j = 0; j < lines.length; j++) {
            final line = lines[j].trim();
            try {
              final parsed = jsonDecode(line) as Map<String, dynamic>;
              _log('Line ${j + 1} return_code: ${parsed['return_code']}');
              if (parsed['return_code'] == 30 && parsed['user'] != null) {
                userData = parsed['user'] as Map<String, dynamic>;
                _log('Found user data in line ${j + 1}.');
                break;
              }
            } catch (e) {
              _log('Line ${j + 1} JSON parse error: $e  |  raw: $line');
            }
          }

          if (userData == null) {
            _log('Line-by-line parse found no user. Trying full-body decode…');
            try {
              final parsed = jsonDecode(body) as Map<String, dynamic>;
              if (parsed['user'] != null) {
                userData = parsed['user'] as Map<String, dynamic>;
                _log('Found user data in full-body decode.');
              } else {
                _log('Full-body decode succeeded but no "user" key found. Keys: ${parsed.keys.toList()}');
              }
            } catch (e) {
              _log('Full-body decode failed: $e');
            }
          }

          if (userData == null) {
            final err = Exception(
                'Could not parse user profile from response. Body was: $body');
            _log('ERROR: ${err.toString()}');
            throw err;
          }

          final user = UserModel.fromJson(userData);
          _cachedUser = user;
          _log('Profile fetched successfully. username=${user.username} id=${user.id}');
          return user;

        } else if (response.statusCode == 401) {
          _log('ERROR: 401 Unauthorized. Token is invalid or expired.');
          throw Exception('Unauthorized');

        } else {
          String errorMsg;
          try {
            final error = jsonDecode(response.body) as Map<String, dynamic>;
            errorMsg = error['error_description'] ??
                error['message'] ??
                'HTTP ${response.statusCode}';
          } catch (_) {
            errorMsg = 'HTTP ${response.statusCode} — body: ${response.body}';
          }
          _log('ERROR from server: $errorMsg');
          lastError = Exception(errorMsg);
        }
      } catch (e) {
        if (e.toString().contains('Unauthorized')) {
          _log('Unauthorized error — not retrying.');
          rethrow;
        }
        _log('Request to $url failed with: $e');
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }

    final finalError =
        lastError ?? Exception('Failed to fetch profile from all endpoints');
    _log('All endpoints exhausted. Throwing: $finalError');
    throw finalError;
  }
}