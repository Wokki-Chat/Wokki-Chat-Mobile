import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LastLoginInfo {
  final DateTime time;
  final String? username;
  final String? email;
  final String? avatarUrl;

  const LastLoginInfo({
    required this.time,
    this.username,
    this.email,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'username': username,
        'email': email,
        'avatar_url': avatarUrl,
      };

  static LastLoginInfo? fromJson(Map<String, dynamic> map) {
    final time = DateTime.tryParse(map['time'] ?? '');
    if (time == null) return null;
    return LastLoginInfo(
      time: time,
      username: map['username'] as String?,
      email: map['email'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }
}

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _accessTokenExpiryKey = 'access_token_expiry';
  static const _savedAccountsKey = 'saved_accounts';

  static Completer<String?>? _refreshCompleter;

  static String _refreshKey(String email) =>
      'refresh_token_${email.toLowerCase().trim()}';

  Future<bool> hasAccessToken() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<bool> isAccessTokenValid() async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token == null || token.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final expiryMs = prefs.getInt(_accessTokenExpiryKey);
    if (expiryMs == null) return false;

    final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMs);
    final valid = DateTime.now().isBefore(expiry.subtract(const Duration(seconds: 30)));
    developer.log('[TOKEN] Access token expiry: $expiry - valid: $valid', name: 'AuthService');
    return valid;
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    int expiresIn = 604800,
  }) async {
    final expiryMs = DateTime.now()
        .add(Duration(seconds: expiresIn))
        .millisecondsSinceEpoch;
    final prefs = await SharedPreferences.getInstance();

    await _storage.write(key: _accessTokenKey, value: accessToken);
    await prefs.setInt(_accessTokenExpiryKey, expiryMs);

    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<void> saveRefreshTokenForAccount(String email, String refreshToken) async {
    await _storage.write(key: _refreshKey(email), value: refreshToken);
  }

  Future<String?> getRefreshTokenForAccount(String email) async {
    return await _storage.read(key: _refreshKey(email));
  }

  Future<void> deleteRefreshTokenForAccount(String email) async {
    await _storage.delete(key: _refreshKey(email));
  }

  Future<String?> ensureValidToken(
      Future<Map<String, dynamic>> Function(String) doRefresh) async {
    if (await isAccessTokenValid()) {
      return await getAccessToken();
    }

    developer.log('[TOKEN] Access token expired or missing', name: 'AuthService');

    if (_refreshCompleter != null) {
      developer.log('[TOKEN] Refresh already in progress, waiting…', name: 'AuthService');
      return await _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        developer.log('[TOKEN] No refresh token available', name: 'AuthService');
        _refreshCompleter!.complete(null);
        return null;
      }

      developer.log('[TOKEN] Sending refresh request…', name: 'AuthService');
      final response = await doRefresh(refreshToken);

      await saveTokens(
        accessToken: response['access_token'],
        refreshToken: response['refresh_token'],
        expiresIn: (response['expires_in'] as num?)?.toInt() ?? 604800,
      );

      final newToken = response['access_token'] as String;
      developer.log('[TOKEN] Refresh successful', name: 'AuthService');
      _refreshCompleter!.complete(newToken);
      return newToken;
    } catch (e) {
      developer.log('[TOKEN] Refresh FAILED: $e', name: 'AuthService');
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> recordLastLogin({
    String? username,
    String? email,
    String? avatarUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getSavedAccounts();

    final updated = existing
        .where((a) =>
            a.email == null ||
            email == null ||
            a.email!.toLowerCase() != email!.toLowerCase())
        .toList();

    updated.insert(
      0,
      LastLoginInfo(
        time: DateTime.now(),
        username: username,
        email: email,
        avatarUrl: avatarUrl,
      ),
    );

    final trimmed = updated.take(5).toList();

    await prefs.setString(
      _savedAccountsKey,
      jsonEncode(trimmed.map((a) => a.toJson()).toList()),
    );
  }

  static Future<List<LastLoginInfo>> getSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedAccountsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => LastLoginInfo.fromJson(e as Map<String, dynamic>))
          .whereType<LastLoginInfo>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await prefs.remove(_accessTokenExpiryKey);
  }
}