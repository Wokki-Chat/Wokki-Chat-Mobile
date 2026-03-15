import 'package:flutter/material.dart';
import 'package:wokki_chat/models/server_model.dart';

class ChatOverlayState {
  final ServerModel? server;
  final ChannelModel? channel;
  final bool visible;
  final double dragValue;

  const ChatOverlayState({
    this.server,
    this.channel,
    this.visible = false,
    this.dragValue = 0.0,
  });
}

class ChatOverlayNotifier extends ValueNotifier<ChatOverlayState> {
  ChatOverlayNotifier() : super(const ChatOverlayState());

  void show(ServerModel server, ChannelModel channel) {
    value = ChatOverlayState(
      server: server,
      channel: channel,
      visible: true,
      dragValue: value.dragValue,
    );
  }

  void hide() {
    value = ChatOverlayState(
      server: value.server,
      channel: value.channel,
      visible: false,
      dragValue: 0.0,
    );
  }

  set dragValue(double v) {
    value = ChatOverlayState(
      server: value.server,
      channel: value.channel,
      visible: value.visible,
      dragValue: v,
    );
  }

  double get dragValue => value.dragValue;

  void cancelDrag() {
    value = ChatOverlayState(
      server: value.server,
      channel: value.channel,
      visible: false,
      dragValue: 0.0,
    );
  }
}