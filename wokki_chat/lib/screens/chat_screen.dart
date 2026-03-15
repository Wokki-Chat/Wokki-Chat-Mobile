import 'package:flutter/material.dart';
import 'package:wokki_chat/models/server_model.dart';
import 'package:wokki_chat/theme/app_theme.dart';
import 'package:wokki_chat/theme/app_colors_provider.dart';

class ChatScreen extends StatefulWidget {
  final ServerModel server;
  final ChannelModel channel;
  final VoidCallback onShowSidebar;

  const ChatScreen({
    super.key,
    required this.server,
    required this.channel,
    required this.onShowSidebar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with ThemeAware<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = appColors;

    return Scaffold(
      backgroundColor: colors.surfaceA0,
      body: Column(
        children: [
          _ChannelTopBar(
            channel: widget.channel,
            colors: colors,
            onMenuTap: widget.onShowSidebar,
          ),
          Expanded(
            child: Center(
              child: Text(
                'No messages yet.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: colors.textA40,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelTopBar extends StatelessWidget {
  final ChannelModel channel;
  final dynamic colors;
  final VoidCallback onMenuTap;

  const _ChannelTopBar({
    required this.channel,
    required this.colors,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        decoration: BoxDecoration(
          color: colors.popupA0,
          border: Border(
            bottom: BorderSide(color: colors.popupA10, width: 1),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onMenuTap,
              icon: Icon(
                Icons.menu_rounded,
                color: colors.textA20,
                size: 22,
              ),
            ),
            Icon(
              channel.type == 'text'
                  ? Icons.tag_rounded
                  : Icons.volume_up_rounded,
              size: 18,
              color: colors.textA30,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                channel.name,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textA0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}