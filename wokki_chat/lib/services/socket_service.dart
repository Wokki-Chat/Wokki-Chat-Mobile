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

    final options = <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {'access_token': accessToken},
    };

    if (AppConfig.allowSelfSigned) {
      options['extraHeaders'] = <String, String>{};
      options['rejectUnauthorized'] = false;
    }

    _socket = io.io(url, options);

    _socket!.onConnect((_) {
      _isConnected = true;
      developer.log('[SOCKET] Connected', name: 'SocketService');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      developer.log('[SOCKET] Disconnected', name: 'SocketService');
    });

    _socket!.onConnectError((data) {
      developer.log('[SOCKET] Connection error: $data', name: 'SocketService');
    });

    _socket!.onError((data) {
      developer.log('[SOCKET] Error: $data', name: 'SocketService');
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
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
    developer.log('[SOCKET] Manually disconnected', name: 'SocketService');
  }
}