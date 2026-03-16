import 'package:flutter/foundation.dart';

class ChatOverlayState {
  final bool visible;
  final String? server;
  final String? channel;
  final String? userId;
  final List<Map<String, dynamic>>? channels;
  final List<Map<String, dynamic>>? users;
  final double dragValue;
  final String? accessToken;

  const ChatOverlayState({
    this.visible = false,
    this.server,
    this.channel,
    this.userId,
    this.channels,
    this.users,
    this.dragValue = 0.0,
    this.accessToken,
  });

  ChatOverlayState copyWith({
    bool? visible,
    String? server,
    String? channel,
    String? userId,
    List<Map<String, dynamic>>? channels,
    List<Map<String, dynamic>>? users,
    double? dragValue,
  }) {
    return ChatOverlayState(
      visible: visible ?? this.visible,
      server: server ?? this.server,
      channel: channel ?? this.channel,
      userId: userId ?? this.userId,
      channels: channels ?? this.channels,
      users: users ?? this.users,
      dragValue: dragValue ?? this.dragValue,
    );
  }
}

class ChatOverlayNotifier extends ValueNotifier<ChatOverlayState> {
  ChatOverlayNotifier() : super(const ChatOverlayState());

  void show({
    required String server,
    required String channel,
    required String accessToken,
    String? userId,
    List<Map<String, dynamic>>? channels,
    List<Map<String, dynamic>>? users,
  }) {
    value = ChatOverlayState(
      visible: true,
      server: server,
      channel: channel,
      userId: userId,
      channels: channels,
      users: users,
      accessToken: accessToken,
    );
  }

  void hide() {
    value = value.copyWith(visible: false, dragValue: 0.0);
  }

  void updateDragValue(double dragValue) {
    value = value.copyWith(dragValue: dragValue);
  }

  void updateUsers(List<Map<String, dynamic>> users) {
    value = value.copyWith(users: users);
  }

  void updateChannels(List<Map<String, dynamic>> channels) {
    value = value.copyWith(channels: channels);
  }
}