import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wokki_chat/config/app_config.dart';
import 'package:wokki_chat/models/server_model.dart';
import 'package:wokki_chat/services/device_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServerService {
  static List<ServerModel>? _cachedServers;
  static const _cacheKey = 'cached_servers';

  static List<ServerModel>? get cachedServers => _cachedServers;

  static void clearCache() {
    _cachedServers = null;
    _clearPersistedServers();
  }

  static Future<List<ServerModel>?> loadCachedServers() async {
    if (_cachedServers != null) return _cachedServers;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_cacheKey);
      if (stored == null) return null;
      final List<dynamic> jsonList = jsonDecode(stored);
      final servers = jsonList
          .map((json) => ServerModel.fromJson(json as Map<String, dynamic>))
          .toList();
      _cachedServers = servers;
      return servers;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _persistServers(List<ServerModel> servers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = servers.map((s) => {
        'id': s.id,
        'name': s.name,
        'description': s.description,
        'image': s.image,
        'created_by': s.createdBy,
        'created_at': s.createdAt,
        'server_type': s.serverType,
        'position': s.position,
        'joined_at': s.joinedAt,
        'channel_groups': s.channelGroups.map((g) => {
          'id': g.id,
          'name': g.name,
          'created_at': g.createdAt,
          'updated_at': g.updatedAt,
          'index': g.index,
          'channels': g.channels.map((c) => {
            'id': c.id,
            'name': c.name,
            'type': c.type,
            'created_at': c.createdAt,
            'updated_at': c.updatedAt,
            'is_default': c.isDefault,
            'index': c.index,
            'group_id': c.groupId,
          }).toList(),
        }).toList(),
      }).toList();
      await prefs.setString(_cacheKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  static Future<void> _clearPersistedServers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (_) {}
  }

  static Future<List<ServerModel>> fetchMyServers(String validToken) async {
    final deviceId = await DeviceService.getDeviceId();

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $validToken',
      'X-Device-ID': deviceId,
    };

    final urls = [
      '${AppConfig.apiUrl}/me/servers',
      if (AppConfig.apiUrlFallback.isNotEmpty)
        '${AppConfig.apiUrlFallback}/me/servers',
    ];

    Exception? lastError;

    for (final url in urls) {
      try {
        final response = await http
            .get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final List<dynamic> jsonList = jsonDecode(response.body);
          final servers = jsonList
              .map((json) => ServerModel.fromJson(json as Map<String, dynamic>))
              .toList();
          _cachedServers = servers;
          await _persistServers(servers);
          return servers;
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

    throw lastError ?? Exception('Failed to fetch servers from all endpoints');
  }
}