import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/message.dart';
import '../widgets/message_widget.dart';
import '../widgets/date_separator.dart';
import '../services/socket_service.dart';

class ChatScreen extends StatefulWidget {
  final String channelId;
  final String serverId;
  final String? userId;
  final String? accessToken;
  final List<Map<String, dynamic>> channels;
  final List<Map<String, dynamic>> users;
  final VoidCallback? onShowSidebar;

  const ChatScreen({
    super.key,
    required this.channelId,
    required this.serverId,
    this.userId,
    this.accessToken,
    this.channels = const [],
    this.users = const [],
    this.onShowSidebar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final List<Message> _messages = [];
  final Map<String, Message> _messageCache = {};

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _pinToBottom = true;
  String? _replyingToId;

  int _offset = 0;
  static const int _limit = 25;

  final _socketService = SocketService();

  String get userId => widget.userId ?? '';
  String get accessToken => widget.accessToken ?? '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadCachedMessages();
    _setupSocketListeners();
    _requestMessages(0);
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channelId != widget.channelId ||
        oldWidget.serverId != widget.serverId) {
      _removeSocketListeners();
      setState(() {
        _messages.clear();
        _messageCache.clear();
        _isLoading = true;
        _offset = 0;
        _replyingToId = null;
      });
      _loadCachedMessages();
      _setupSocketListeners();
      _requestMessages(0);
    }
  }

  @override
  void dispose() {
    _removeSocketListeners();
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _setupSocketListeners() {
    _socketService.on('all_messages', _onAllMessages);
    _socketService.on('all_messages_nocache', _onAllMessages);
    _socketService.on('new_message', _onNewMessage);
    _socketService.on('update_message', _onUpdateMessage);
    _socketService.on('message_deleted', _onMessageDeleted);
  }

  void _removeSocketListeners() {
    _socketService.off('all_messages', _onAllMessages);
    _socketService.off('all_messages_nocache', _onAllMessages);
    _socketService.off('new_message', _onNewMessage);
    _socketService.off('update_message', _onUpdateMessage);
    _socketService.off('message_deleted', _onMessageDeleted);
  }

  void _requestMessages(int offsetValue) {
    _socketService.socket?.emit('get_messages', {
      'access_token': accessToken,
      'server_id': widget.serverId,
      'channel_id': widget.channelId,
      'offset': offsetValue,
    });
  }

  void _onAllMessages(dynamic data) {
    if (!mounted) return;
    final List<dynamic> raw = data is List ? data : [];
    final incoming = raw.map((j) => Message.fromJson(j as Map<String, dynamic>)).toList();

    setState(() {
      if (_offset == 0) {
        _messages.clear();
        _messageCache.clear();
        _messages.addAll(incoming);
      } else {
        _messages.insertAll(0, incoming);
      }
      for (final m in incoming) {
        _messageCache[m.id] = m;
      }
      _isLoading = false;
      _isLoadingMore = false;
    });

    _saveMessagesToCache();

    if (_offset == 0 && _pinToBottom) {
      _scrollToBottom();
    }
  }

  void _onNewMessage(dynamic data) {
    if (!mounted) return;
    final msg = Message.fromJson(data as Map<String, dynamic>);
    if (msg.id.isEmpty) return;
    if (data['channel_id']?.toString() != widget.channelId) return;

    final isAtBottom = _scrollController.hasClients &&
        (_scrollController.position.maxScrollExtent -
                _scrollController.position.pixels) <
            50;

    setState(() {
      _messages.add(msg);
      _messageCache[msg.id] = msg;
    });

    _saveMessagesToCache();

    if (isAtBottom) {
      _scrollToBottom();
    }
  }

  void _onUpdateMessage(dynamic data) {
    if (!mounted) return;
    final updated = Message.fromJson(data as Map<String, dynamic>);
    final index = _messages.indexWhere((m) => m.id == updated.id);
    if (index == -1) return;
    setState(() {
      _messages[index] = updated;
      _messageCache[updated.id] = updated;
    });
    _saveMessagesToCache();
  }

  void _onMessageDeleted(dynamic data) {
    if (!mounted) return;
    final messageId = data['message_id']?.toString() ?? '';
    if (messageId.isEmpty) return;
    setState(() {
      _messages.removeWhere((m) => m.id == messageId);
      _messageCache.remove(messageId);
    });
    _saveMessagesToCache();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels <= 50 && !_isLoadingMore && !_isLoading) {
      _loadMoreMessages();
    }

    final isAtBottom =
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 10;
    if (_pinToBottom != isAtBottom) {
      setState(() => _pinToBottom = isAtBottom);
    }
  }

  void _loadMoreMessages() {
    setState(() {
      _isLoadingMore = true;
      _offset += _limit;
    });
    _requestMessages(_offset);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _socketService.socket?.emit('send_message', {
      'access_token': accessToken,
      'server_id': widget.serverId,
      'channel_id': widget.channelId,
      'message': text,
      if (_replyingToId != null) 'reply_to': _replyingToId,
    });

    _inputController.clear();
    setState(() => _replyingToId = null);
  }

  Future<void> _loadCachedMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'messages_${widget.serverId}_${widget.channelId}';
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null && mounted) {
        final List<dynamic> jsonList = json.decode(cachedData);
        final messages = jsonList.map((j) => Message.fromJson(j)).toList();
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
          _messageCache.clear();
          for (var msg in messages) {
            _messageCache[msg.id] = msg;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _saveMessagesToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'messages_${widget.serverId}_${widget.channelId}';
      final jsonList = _messages.map((m) => {
            'id': m.id,
            'message': m.message,
            'created_at': m.createdAt,
            'sent_by': m.sentBy,
            'sent_by_bot': m.sentByBot,
            'edited': m.edited,
            'sender_info': {
              'username': m.senderInfo.username,
              'display_name': m.senderInfo.displayName,
              'profile_picture': m.senderInfo.profilePicture,
              'premium': m.senderInfo.premium,
              'staff': m.senderInfo.staff,
            },
            'embed': m.embed,
            'parent_message_info': m.parentMessageInfo != null
                ? {
                    'message_id': m.parentMessageInfo!.messageId,
                    'username': m.parentMessageInfo!.username,
                    'message_preview': m.parentMessageInfo!.messagePreview,
                  }
                : null,
            'command_info': m.commandInfo != null
                ? {
                    'username': m.commandInfo!.username,
                    'command': m.commandInfo!.command,
                  }
                : null,
            'assets': m.assets
                ?.map((a) => {
                      'savedName': a.savedName,
                      'originalName': a.originalName,
                    })
                .toList(),
            'reactions': m.reactions
                ?.map((r) => {
                      'reaction': r.reaction,
                      'user_id': r.userId,
                      'super_reaction': r.superReaction,
                    })
                .toList(),
            'bot_message': m.botMessage,
          }).toList();
      await prefs.setString(cacheKey, json.encode(jsonList));
    } catch (_) {}
  }

  void _handleReply(String messageId) {
    setState(() => _replyingToId = messageId);
  }

  void _handleEdit(String messageId) {
    final msg = _messageCache[messageId];
    if (msg == null) return;
    _inputController.text = msg.message;
  }

  void _handleDelete(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF303030)
            : const Color(0xFFF0F0F0),
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _socketService.socket?.emit('delete_message', {
                'access_token': accessToken,
                'server_id': widget.serverId,
                'channel_id': widget.channelId,
                'message_id': messageId,
              });
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFFF7C7C))),
          ),
        ],
      ),
    );
  }

  void _handleReact(String messageId, String emoji) {
    _socketService.socket?.emit('react', {
      'access_token': accessToken,
      'server_id': widget.serverId,
      'channel_id': widget.channelId,
      'message_id': messageId,
      'reaction': emoji,
    });
  }

  bool _isCompact(int index) {
    if (index == 0) return false;
    final current = _messages[index];
    final previous = _messages[index - 1];
    if (current.senderId != previous.senderId) return false;
    try {
      final currentTime = DateTime.parse(current.createdAt);
      final previousTime = DateTime.parse(previous.createdAt);
      if (currentTime.difference(previousTime).inMinutes > 10) return false;
    } catch (_) {
      return false;
    }
    if (current.parentMessageInfo != null || current.commandInfo != null) return false;
    return true;
  }

  bool _isMentioned(Message message) {
    return message.message.contains('<@$userId>') ||
        message.message.contains('<@everyone>');
  }

  bool _needsDateSeparator(int index) {
    if (index == 0) return true;
    try {
      final current = DateTime.parse(_messages[index].createdAt);
      final previous = DateTime.parse(_messages[index - 1].createdAt);
      return current.day != previous.day ||
          current.month != previous.month ||
          current.year != previous.year;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFFFFFFF),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? _buildSkeletonLoader(isDark)
                : Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == 0 && _isLoadingMore) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF895BF5)),
                                ),
                              ),
                            );
                          }

                          final msgIndex = _isLoadingMore ? index - 1 : index;
                          final message = _messages[msgIndex];
                          final isCompact = _isCompact(msgIndex);
                          final isMentioned = _isMentioned(message);
                          final needsSeparator = _needsDateSeparator(msgIndex);

                          return Column(
                            children: [
                              if (needsSeparator)
                                DateSeparator(date: DateTime.tryParse(message.createdAt) ?? DateTime.now()),
                              Slidable(
                                key: ValueKey(message.id),
                                endActionPane: ActionPane(
                                  motion: const DrawerMotion(),
                                  extentRatio: 0.2,
                                  children: [
                                    SlidableAction(
                                      onPressed: (_) => _handleReply(message.id),
                                      backgroundColor: const Color(0xFF895BF5),
                                      foregroundColor: Colors.white,
                                      icon: Icons.reply,
                                      label: 'Reply',
                                    ),
                                  ],
                                ),
                                child: MessageWidget(
                                  message: message,
                                  isCompact: isCompact,
                                  isMentioned: isMentioned,
                                  currentUserId: userId,
                                  channels: widget.channels,
                                  users: widget.users,
                                  onReply: _handleReply,
                                  onEdit: _handleEdit,
                                  onDelete: _handleDelete,
                                  onReact: _handleReact,
                                  onUserTap: (_) {},
                                  onChannelTap: (_) {},
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      if (!_pinToBottom)
                        Positioned(
                          bottom: 8,
                          right: 12,
                          child: GestureDetector(
                            onTap: _scrollToBottom,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF895BF5),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 6,
                                  )
                                ],
                              ),
                              child: const Icon(Icons.arrow_downward, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          if (_replyingToId != null) _buildReplyingBanner(isDark),
          _buildMessageInput(isDark),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5),
      highlightColor: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF2F2F2),
      child: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 16,
                        decoration: BoxDecoration(
                            color: Colors.white, borderRadius: BorderRadius.circular(4)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                            color: Colors.white, borderRadius: BorderRadius.circular(4)),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 200,
                        height: 14,
                        decoration: BoxDecoration(
                            color: Colors.white, borderRadius: BorderRadius.circular(4)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReplyingBanner(bool isDark) {
    final replyMessage = _messageCache[_replyingToId];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : const Color(0xFFF5F5F5),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF282828) : const Color(0xFFE0E0E0),
          ),
        ),
      ),
      child: Row(
        children: [
          const Text('Replying to:'),
          const SizedBox(width: 5),
          Text(
            replyMessage?.senderInfo.username ?? 'Unknown',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFB2B2B2) : const Color(0xFF4D4D4D),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => setState(() => _replyingToId = null),
            color: isDark ? const Color(0xFFB2B2B2) : const Color(0xFF4D4D4D),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : const Color(0xFFF5F5F5),
        border: Border.all(
          color: isDark ? const Color(0xFF3B3B3B) : const Color(0xFFCCCCCC),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {},
            color: isDark ? const Color(0xFFB2B2B2) : const Color(0xFF4D4D4D),
          ),
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined),
            onPressed: () {},
            color: isDark ? const Color(0xFFB2B2B2) : const Color(0xFF4D4D4D),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            color: const Color(0xFF895BF5),
          ),
        ],
      ),
    );
  }
}