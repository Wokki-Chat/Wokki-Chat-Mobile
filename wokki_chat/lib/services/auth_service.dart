import 'dart:convert';
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
  static const _savedAccountsKey = 'saved_accounts';

  static String _refreshKey(String email) =>
      'refresh_token_${email.toLowerCase().trim()}';

  Map<String, dynamic>? _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      var normalized = base64Url.normalize(payload);
      var decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  bool _isTokenExpired(String token) {
    final payload = _decodeJwt(token);
    if (payload == null) return true;
    
    final exp = payload['exp'];
    if (exp == null) return true;
    
    final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    final now = DateTime.now();
    
    return now.isAfter(expiryDate.subtract(const Duration(seconds: 30)));
  }

  Future<bool> hasAccessToken() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<bool> isAccessTokenValid() async {
    final token = await getAccessToken();
    if (token == null) return false;
    return !_isTokenExpired(token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<void> saveRefreshTokenForAccount(
      String email, String refreshToken) async {
    await _storage.write(key: _refreshKey(email), value: refreshToken);
  }

  Future<String?> getRefreshTokenForAccount(String email) async {
    return await _storage.read(key: _refreshKey(email));
  }

  Future<void> deleteRefreshTokenForAccount(String email) async {
    await _storage.delete(key: _refreshKey(email));
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
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}