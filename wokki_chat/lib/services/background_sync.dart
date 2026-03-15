import 'dart:developer' as developer;
import 'package:wokki_chat/services/auth_service.dart';
import 'package:wokki_chat/services/api_service.dart';
import 'package:wokki_chat/services/user_service.dart';
import 'package:wokki_chat/services/server_service.dart';
import 'package:wokki_chat/models/user_model.dart';
import 'package:wokki_chat/models/server_model.dart';

class BackgroundSync {
  static Future<({UserModel? user, List<ServerModel>? servers})> run() async {
    developer.log('[SYNC] Starting background sync', name: 'BackgroundSync');

    final authService = AuthService();
    final token = await authService.ensureValidToken(ApiService.refreshToken);

    if (token == null) {
      developer.log('[SYNC] No valid token — skipping sync', name: 'BackgroundSync');
      return (user: null, servers: null);
    }

    developer.log('[SYNC] Token ready, fetching profile and servers in parallel', name: 'BackgroundSync');

    final results = await Future.wait([
      UserService.fetchMyProfile(token).then<UserModel?>((u) => u).catchError((_) => null),
      ServerService.fetchMyServers(token).then<List<ServerModel>?>((s) => s).catchError((_) => null),
    ]);

    final user = results[0] as UserModel?;
    final servers = results[1] as List<ServerModel>?;

    developer.log(
      '[SYNC] Done — user: ${user != null ? "ok" : "failed"}, servers: ${servers != null ? "${servers.length} loaded" : "failed"}',
      name: 'BackgroundSync',
    );

    return (user: user, servers: servers);
  }
}