import 'dart:developer' as developer;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:wokki_chat/config/app_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  io.Socket? get socket => _socket;

  void connect(String accessToken) {
    if (_socket != null && _isConnected) return;

    final url = AppConfig.socketUrl;
    if (url.isEmpty) {
      developer.log('[SOCKET] No SOCKET_URL configured', name: 'SocketService');
      return;
    }

    developer.log('[SOCKET] Connecting to $url', name: 'SocketService');

    _socket?.dispose();
    _socket = null;

    final opts = io.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .setQuery({'access_token': accessToken})
        .setReconnectionDelay(2000)
        .setReconnectionDelayMax(10000)
        .enableReconnection()
        .build();

    _socket = io.io(url, opts);

    _socket!.onConnect((_) {
      _isConnected = true;
      developer.log('[SOCKET] Connected', name: 'SocketService');
    });

    _socket!.onDisconnect((reason) {
      _isConnected = false;
      developer.log('[SOCKET] Disconnected: $reason', name: 'SocketService');
    });

    _socket!.onConnectError((data) {
      developer.log('[SOCKET] Connection error: $data', name: 'SocketService');
    });

    _socket!.onError((data) {
      developer.log('[SOCKET] Error: $data', name: 'SocketService');
    });

    _socket!.onReconnect((_) {
      developer.log('[SOCKET] Reconnected', name: 'SocketService');
    });

    _socket!.connect();
  }

  void changeRoom({
    required String accessToken,
    required String serverId,
    required String channelId,
  }) {
    if (_socket == null || !_isConnected) {
      developer.log('[SOCKET] Cannot change room - not connected', name: 'SocketService');
      return;
    }

    developer.log('[SOCKET] Changing room to server=$serverId channel=$channelId', name: 'SocketService');

    _socket!.emit('change_room', {
      'access_token': accessToken,
      'server_id': serverId,
      'channel_id': channelId,
    });
  }

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event, [Function(dynamic)? handler]) {
    if (handler != null) {
      _socket?.off(event, handler);
    } else {
      _socket?.off(event);
    }
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    developer.log('[SOCKET] Manually disconnected', name: 'SocketService');
  }
}