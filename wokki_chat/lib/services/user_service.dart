import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wokki_chat/config/app_config.dart';
import 'package:wokki_chat/models/user_model.dart';
import 'package:wokki_chat/services/device_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static UserModel? _cachedUser;
  static const _cacheKey = 'cached_user';

  static UserModel? get cachedUser => _cachedUser;

  static void clearCache() {
    _cachedUser = null;
    _clearPersistedUser();
  }

  static Future<UserModel?> loadCachedUser() async {
    if (_cachedUser != null) return _cachedUser;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_cacheKey);
      if (stored == null) return null;
      final user = UserModel.fromJson(jsonDecode(stored) as Map<String, dynamic>);
      _cachedUser = user;
      return user;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _persistUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode({
        'id': user.id,
        'username': user.username,
        'display_name': user.displayName,
        'email': user.email,
        'bio': user.bio,
        'status': user.status,
        'avatar': user.avatar,
        'banner': user.banner,
        'accent_color': user.accentColor,
        'primary_color': user.primaryColor,
        'premium': user.premium,
        'staff': user.staff,
        'developer': user.developer,
        'bot': user.bot,
        'tags': user.tags,
        'connections': user.connections,
        'created_at': user.createdAt,
      }));
    } catch (_) {}
  }

  static Future<void> _clearPersistedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (_) {}
  }

  static Future<UserModel> fetchMyProfile(String validToken) async {
    final deviceId = await DeviceService.getDeviceId();

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $validToken',
      'X-Device-ID': deviceId,
    };

    final urls = [
      '${AppConfig.apiUrl}/me/profile',
      if (AppConfig.apiUrlFallback.isNotEmpty)
        '${AppConfig.apiUrlFallback}/me/profile',
    ];

    Exception? lastError;

    for (final url in urls) {
      try {
        final response = await http
            .get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final userData = _extractUser(response.body);
          if (userData == null) {
            throw Exception('Could not parse user profile from response.');
          }
          final user = UserModel.fromJson(userData);
          _cachedUser = user;
          await _persistUser(user);
          return user;
        } else if (response.statusCode == 401) {
          throw Exception('Unauthorized');
        } else {
          String msg;
          try {
            final err = jsonDecode(response.body) as Map<String, dynamic>;
            msg = err['error_description'] ?? err['message'] ?? 'HTTP ${response.statusCode}';
          } catch (_) {
            msg = 'HTTP ${response.statusCode}';
          }
          lastError = Exception(msg);
        }
      } catch (e) {
        if (e.toString().contains('Unauthorized') ||
            e.toString().contains('Session expired')) rethrow;
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }

    throw lastError ?? Exception('Failed to fetch profile from all endpoints');
  }

  static Map<String, dynamic>? _extractUser(String body) {
    for (final line in body.split('\n')) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('{')) continue;
      try {
        final parsed = jsonDecode(trimmed) as Map<String, dynamic>;
        if (parsed['return_code'] == 30 && parsed['user'] != null) {
          return parsed['user'] as Map<String, dynamic>;
        }
      } catch (_) {}
    }
    return null;
  }
}