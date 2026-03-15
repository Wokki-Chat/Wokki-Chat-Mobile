import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import 'markdown_renderer.dart';
import 'reactions_widget.dart';
import 'image_viewer_dialog.dart';
import 'emoji_picker_widget.dart';

class MessageWidget extends StatefulWidget {
  final Message message;
  final bool isCompact;
  final bool isMentioned;
  final String currentUserId;
  final List<Map<String, dynamic>> channels;
  final List<Map<String, dynamic>> users;
  final Function(String messageId)? onReply;
  final Function(String messageId)? onEdit;
  final Function(String messageId)? onDelete;
  final Function(String messageId, String emoji)? onReact;
  final Function(String userId)? onUserTap;
  final Function(String channelId)? onChannelTap;

  const MessageWidget({
    super.key,
    required this.message,
    this.isCompact = false,
    this.isMentioned = false,
    required this.currentUserId,
    this.channels = const [],
    this.users = const [],
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onReact,
    this.onUserTap,
    this.onChannelTap,
  });

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOwnMessage = widget.message.senderId == widget.currentUserId;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onLongPress: () => _showMessageOptions(context),
        child: Container(
          padding: const EdgeInsets.all(10),
          margin: widget.isCompact
              ? const EdgeInsets.only(top: 0)
              : const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: widget.isMentioned
                ? Colors.yellow.withOpacity(0.2)
                : (_isHovered
                    ? (isDark ? const Color(0xFF141414) : const Color(0xFFF5F5F5))
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.message.parentMessageInfo != null)
                _buildReplyPreview(isDark),
              if (widget.message.commandInfo != null)
                _buildCommandInfo(isDark),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.isCompact) _buildProfilePicture(),
                  if (widget.isCompact) const SizedBox(width: 40),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!widget.isCompact) _buildMessageHeader(isDark),
                        _buildMessageContent(isDark),
                        if (widget.message.assets != null && widget.message.assets!.isNotEmpty)
                          _buildAssets(),
                        if (widget.message.reactions != null && widget.message.reactions!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: ReactionsWidget(
                              reactions: widget.message.reactions!,
                              currentUserId: widget.currentUserId,
                              onReactionTap: (emoji) => widget.onReact?.call(widget.message.id, emoji),
                              onAddReaction: () => _showEmojiPicker(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_isHovered && !widget.isCompact)
                Positioned(
                  top: 5,
                  right: 5,
                  child: _buildMessageOptions(isDark, isOwnMessage),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePicture() {
    return GestureDetector(
      onTap: () => widget.onUserTap?.call(widget.message.senderId),
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.only(right: 10),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: widget.message.senderInfo.profilePicture,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: const Color(0xFF895BF5),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            errorWidget: (context, url, error) => Container(
              color: const Color(0xFF895BF5),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageHeader(bool isDark) {
    final displayName = widget.message.senderInfo.displayName ?? widget.message.senderInfo.username;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => widget.onUserTap?.call(widget.message.senderId),
            child: Text(
              displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          if (widget.message.senderInfo.premium) ...[
            const SizedBox(width: 5),
            _buildTag('Premium', const Color(0xFF895BF5)),
          ],
          if (widget.message.senderInfo.staff > 0) ...[
            const SizedBox(width: 5),
            _buildTag('Staff', const Color(0xFF895BF5)),
          ],
          if (widget.message.botMessage == 1) ...[
            const SizedBox(width: 5),
            _buildTag('BOT', const Color(0xFF895BF5)),
          ],
          const SizedBox(width: 10),
          Text(
            _formatDate(widget.message.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFFB2B2B2) : const Color(0xFF4D4D4D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMessageContent(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: MarkdownRenderer(
            context: context,
            currentUserId: widget.currentUserId,
            channels: widget.channels,
            users: widget.users,
            onUserMention: widget.onUserTap,
            onChannelTap: widget.onChannelTap,
          ).render(widget.message.message),
        ),
        if (widget.message.edited == 1)
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Text(
              '(edited)',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFFB2B2B2) : const Color(0xFF4D4D4D),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReplyPreview(bool isDark) {
    final reply = widget.message.parentMessageInfo!;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, left: 40),
      child: Row(
        children: [
          Icon(
            Icons.subdirectory_arrow_left,
            size: 20,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
          const SizedBox(width: 5),
          Text(
            '@${reply.username}',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFFB2B2B2) : const Color(0xFF4D4D4D),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              reply.messagePreview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFFB2B2B2) : const Color(0xFF4D4D4D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandInfo(bool isDark) {
    final command = widget.message.commandInfo!;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, left: 40),
      child: Row(
        children: [
          Icon(
            Icons.subdirectory_arrow_left,
            size: 20,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
          const SizedBox(width: 5),
          Text(
            '@${command.username}',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFFB2B2B2) : const Color(0xFF4D4D4D),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 5),
          const Text('used', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFB691FA).withOpacity(0.3),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              command.command ?? '',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssets() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 5,
        runSpacing: 5,
        children: widget.message.assets!.map((asset) {
          return _buildAsset(asset);
        }).toList(),
      ),
    );
  }

  Widget _buildAsset(Asset asset) {
    switch (asset.assetType) {
      case 'image':
      case 'profile_picture':
        return GestureDetector(
          onTap: () => ImageViewerDialog.show(
            context,
            asset.url,
            asset.originalName,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: asset.url,
              width: asset.assetType == 'profile_picture' ? 350 : 300,
              height: asset.assetType == 'profile_picture' ? 350 : 300,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 300,
                height: 300,
                color: const Color(0xFF404040),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF895BF5)),
                  ),
                ),
              ),
            ),
          ),
        );
      case 'video':
        return Container(
          width: 300,
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF303030),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.play_circle_outline, size: 64, color: Colors.white),
          ),
        );
      case 'audio':
        return Container(
          width: 300,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF303030),
            border: Border.all(color: const Color(0xFF404040)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.music_note, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  asset.originalName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      case 'pdf':
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF303030),
            border: Border.all(color: const Color(0xFF404040)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf, color: Colors.red),
              const SizedBox(width: 10),
              Text(
                asset.originalName,
                style: const TextStyle(
                  color: Color(0xFF895BF5),
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF303030),
            border: Border.all(color: const Color(0xFF404040)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insert_drive_file, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                asset.originalName,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildMessageOptions(bool isDark, bool isOwnMessage) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF303030) : const Color(0xFFF0F0F0),
        border: Border.all(
          color: isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MessageOption(
            icon: Icons.reply,
            onTap: () => widget.onReply?.call(widget.message.id),
          ),
          _MessageOption(
            icon: Icons.add_reaction_outlined,
            onTap: () => _showEmojiPicker(context),
          ),
          if (isOwnMessage) ...[
            _MessageOption(
              icon: Icons.edit,
              onTap: () => widget.onEdit?.call(widget.message.id),
            ),
            _MessageOption(
              icon: Icons.delete,
              color: const Color(0xFFFF7C7C),
              onTap: () => widget.onDelete?.call(widget.message.id),
            ),
          ],
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    final isOwnMessage = widget.message.senderId == widget.currentUserId;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF303030)
              : const Color(0xFFF0F0F0),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                widget.onReply?.call(widget.message.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_reaction_outlined),
              title: const Text('React'),
              onTap: () {
                Navigator.pop(context);
                _showEmojiPicker(context);
              },
            ),
            if (isOwnMessage) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onEdit?.call(widget.message.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Color(0xFFFF7C7C)),
                title: const Text('Delete', style: TextStyle(color: Color(0xFFFF7C7C))),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDelete?.call(widget.message.id);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker(BuildContext context) {
    EmojiPickerDialog.show(
      context,
      (emoji) => widget.onReact?.call(widget.message.id, emoji),
    );
  }

  String _formatDate(String createdAt) {
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays > 7) {
        return DateFormat('MMM d, y h:mm a').format(date);
      } else if (diff.inDays == 1) {
        return 'Yesterday at ${DateFormat('h:mm a').format(date)}';
      } else if (diff.inDays >= 2) {
        return '${diff.inDays} days ago at ${DateFormat('h:mm a').format(date)}';
      } else {
        return DateFormat('h:mm a').format(date);
      }
    } catch (e) {
      return createdAt;
    }
  }
}

class _MessageOption extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _MessageOption({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  State<_MessageOption> createState() => _MessageOptionState();
}

class _MessageOptionState extends State<_MessageOption> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: _isHovered
                ? (isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(
            widget.icon,
            size: 20,
            color: widget.color ?? (isDark ? const Color(0xFFB2B2B2) : const Color(0xFF4D4D4D)),
          ),
        ),
      ),
    );
  }
}