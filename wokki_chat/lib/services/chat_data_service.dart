import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:wokki_chat/state/chat_overlay_notifier.dart';

class ChatDataService {
  final IO.Socket socket;
  final ChatOverlayNotifier overlayNotifier;

  ChatDataService({
    required this.socket,
    required this.overlayNotifier,
  });

  void setupListeners() {
    socket.on('users_list', (data) {
      final users = (data as List).map((u) => {
        'id': u['id'] ?? u['user_id'],
        'username': u['username'],
        'display_name': u['display_name'],
        'profile_picture': u['profile_picture'],
        'premium': u['premium'] ?? false,
        'staff': u['staff'] ?? false,
        'bot': u['bot'] ?? false,
      }).toList();
      
      overlayNotifier.updateUsers(users);
    });

    socket.on('channels_list', (data) {
      final channels = (data as List).map((c) => {
        'name': c['name'],
        'channel_id': c['channel_id'] ?? c['id'],
      }).toList();
      
      overlayNotifier.updateChannels(channels);
    });

    socket.on('user_joined', (data) {
      _refreshUsers();
    });

    socket.on('user_left', (data) {
      _refreshUsers();
    });
  }

  void fetchUsersAndChannels(String serverId) {
    socket.emit('get_users', {'server_id': serverId});
    socket.emit('get_channels', {'server_id': serverId});
  }

  void _refreshUsers() {
    final state = overlayNotifier.value;
    if (state.server != null) {
      socket.emit('get_users', {'server_id': state.server});
    }
  }
}