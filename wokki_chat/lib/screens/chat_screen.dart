import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wokki_chat/models/server_model.dart';
import 'package:wokki_chat/models/message_model.dart';
import 'package:wokki_chat/services/auth_service.dart';
import 'package:wokki_chat/services/socket_service.dart';
import 'package:wokki_chat/services/user_service.dart';
import 'package:wokki_chat/theme/app_colors_provider.dart';


String _twemojiUrl(String emoji) {
  final codePoints = emoji.runes
      .where((r) => r != 0xFE0F && r != 0x200D)
      .map((r) => r.toRadixString(16).toLowerCase())
      .join('-');
  return 'https://cdn.jsdelivr.net/gh/twitter/twemoji@v14.0.2/assets/svg/$codePoints.svg';
}

final _emojiRegex = RegExp(
  r'(?:[\u2700-\u27bf]|(?:\ud83c[\udde6-\uddff]){2}'
  r'|[\ud800-\udbff][\udc00-\udfff]'
  r'|[\u0023-\u0039]\ufe0f?\u20e3'
  r'|\u3299|\u3297|\u303d|\u3030|\u24c2'
  r'|[\ud83c][\udd70-\udd71]'
  r'|[\ud83c][\udd7e-\udd7f]'
  r'|[\ud83c]\udd8e'
  r'|[\ud83c][\udd91-\udd9a]'
  r'|[\ud83c][\udde6-\uddff]'
  r'|[\ud83c][\ude01-\ude02]'
  r'|[\ud83c]\ude1a|\ud83c\ude2f'
  r'|[\ud83c][\ude32-\ude3a]'
  r'|[\ud83c][\ude50-\ude51]'
  r'|\u203c|\u2049'
  r'|[\u25aa-\u25ab]|\u25b6|\u25c0'
  r'|[\u25fb-\u25fe]|\u00a9|\u00ae|\u2122|\u2139'
  r'|[\ud83c]\udc04|[\u2600-\u26FF]|\u2b05|\u2b06|\u2b07|\u2b1b|\u2b1c|\u2b50|\u2b55'
  r'|\u231a|\u231b|\u2328|\u23cf|[\u23e9-\u23f3]|[\u23f8-\u23fa]'
  r'|\ud83c\udccf|\u2934|\u2935|[\u2190-\u21ff])'
  r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])',
);


class _Span {
  final String text;
  final bool bold;
  final bool italic;
  final bool strike;
  final bool code;
  final bool isEmoji;
  final String? linkUrl;
  final String? mention;

  const _Span(this.text, {
    this.bold = false,
    this.italic = false,
    this.strike = false,
    this.code = false,
    this.isEmoji = false,
    this.linkUrl,
    this.mention,
  });
}

List<_Span> _parseInline(String text) {
  final spans = <_Span>[];
  final re = RegExp(
    r'\*\*(.+?)\*\*'
    r'|\*([^*\n]+)\*'
    r'|_([^_\n]+)_'
    r'|~~(.+?)~~'
    r'|`([^`\n]+)`'
    r'|(<@[^>]+>)'
    r'|(https?://\S+)',
    dotAll: false,
  );

  int last = 0;
  for (final m in re.allMatches(text)) {
    if (m.start > last) {
      spans.addAll(_splitEmoji(text.substring(last, m.start)));
    }
    if (m.group(1) != null) {
      spans.add(_Span(m.group(1)!, bold: true));
    } else if (m.group(2) != null) {
      spans.add(_Span(m.group(2)!, italic: true));
    } else if (m.group(3) != null) {
      spans.add(_Span(m.group(3)!, italic: true));
    } else if (m.group(4) != null) {
      spans.add(_Span(m.group(4)!, strike: true));
    } else if (m.group(5) != null) {
      spans.add(_Span(m.group(5)!, code: true));
    } else if (m.group(6) != null) {
      spans.add(_Span(m.group(6)!, mention: m.group(6)!));
    } else if (m.group(7) != null) {
      spans.add(_Span(m.group(7)!, linkUrl: m.group(7)!));
    }
    last = m.end;
  }
  if (last < text.length) {
    spans.addAll(_splitEmoji(text.substring(last)));
  }
  return spans;
}

List<_Span> _splitEmoji(String text) {
  if (text.isEmpty) return [];
  final spans = <_Span>[];
  int last = 0;
  for (final m in _emojiRegex.allMatches(text)) {
    if (m.start > last) {
      spans.add(_Span(text.substring(last, m.start)));
    }
    spans.add(_Span(m.group(0)!, isEmoji: true));
    last = m.end;
  }
  if (last < text.length) spans.add(_Span(text.substring(last)));
  return spans;
}

abstract class _Block {}

class _TextBlock extends _Block {
  final List<_Span> spans;
  _TextBlock(this.spans);
}

class _CodeBlock extends _Block {
  final String lang;
  final String code;
  _CodeBlock(this.lang, this.code);
}

class _QuoteBlock extends _Block {
  final String content;
  _QuoteBlock(this.content);
}

class _HeadingBlock extends _Block {
  final int level;
  final String content;
  _HeadingBlock(this.level, this.content);
}

List<_Block> _parseBlocks(String text) {
  final blocks = <_Block>[];

  final codeBlockRe = RegExp(r'```(\w+)?\n([\s\S]*?)```');
  int last = 0;

  for (final m in codeBlockRe.allMatches(text)) {
    if (m.start > last) {
      blocks.addAll(_parseLinesBlocks(text.substring(last, m.start)));
    }
    blocks.add(_CodeBlock(m.group(1) ?? '', m.group(2) ?? ''));
    last = m.end;
  }
  if (last < text.length) {
    blocks.addAll(_parseLinesBlocks(text.substring(last)));
  }
  return blocks;
}

List<_Block> _parseLinesBlocks(String text) {
  final blocks = <_Block>[];
  for (final line in text.split('\n')) {
    final t = line.trimRight();
    if (t.isEmpty) continue;

    final headingMatch = RegExp(r'^(#{1,6}) (.+)').firstMatch(t);
    if (headingMatch != null) {
      blocks.add(_HeadingBlock(
          headingMatch.group(1)!.length, headingMatch.group(2)!));
      continue;
    }

    if (t.startsWith('> ')) {
      blocks.add(_QuoteBlock(t.substring(2)));
      continue;
    }

    blocks.add(_TextBlock(_parseInline(t)));
  }
  return blocks;
}

class _MarkdownWidget extends StatefulWidget {
  final String text;
  final bool edited;
  final dynamic colors;

  const _MarkdownWidget({
    required this.text,
    required this.edited,
    required this.colors,
  });

  @override
  State<_MarkdownWidget> createState() => _MarkdownWidgetState();
}

class _MarkdownWidgetState extends State<_MarkdownWidget> {
  late List<_Block> _blocks;

  @override
  void initState() {
    super.initState();
    _blocks = _parseBlocks(widget.text);
  }

  @override
  void didUpdateWidget(_MarkdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _blocks = _parseBlocks(widget.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < _blocks.length; i++)
          _buildBlock(context, _blocks[i], colors,
              i == _blocks.length - 1 && widget.edited),
        if (widget.edited && _blocks.isEmpty)
          Text(
            ' (edited)',
            style: TextStyle(
                fontSize: 11,
                color: colors.textA40,
                fontStyle: FontStyle.italic),
          ),
      ],
    );
  }

  Widget _buildBlock(
      BuildContext context, _Block block, dynamic colors, bool isLast) {
    if (block is _CodeBlock) {
      return _CodeBlockWidget(block: block, colors: colors);
    }
    if (block is _QuoteBlock) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: colors.primaryA0, width: 3)),
        ),
        child: Text(block.content,
            style: TextStyle(
                fontSize: 14,
                color: colors.textA30,
                fontFamily: 'Inter',
                height: 1.4)),
      );
    }
    if (block is _HeadingBlock) {
      const sizes = [22.0, 20.0, 18.0, 16.0, 15.0, 14.0];
      final sz = sizes[block.level.clamp(1, 6) - 1];
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 2),
        child: Text(block.content,
            style: TextStyle(
                fontSize: sz,
                fontWeight: FontWeight.w700,
                color: colors.textA0,
                fontFamily: 'Inter')),
      );
    }
    if (block is _TextBlock) {
      return _InlineWidget(
          spans: block.spans, edited: isLast && widget.edited, colors: colors);
    }
    return const SizedBox.shrink();
  }
}

class _InlineWidget extends StatelessWidget {
  final List<_Span> spans;
  final bool edited;
  final dynamic colors;

  const _InlineWidget({
    required this.spans,
    required this.edited,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: 14,
      color: colors.textA10,
      fontFamily: 'Inter',
      height: 1.4,
    );

    final inlineChildren = <InlineSpan>[];
    for (final span in spans) {
      if (span.isEmoji) {
        inlineChildren.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _TwemojiWidget(emoji: span.text, size: 18),
        ));
        continue;
      }

      TextStyle style = baseStyle;
      if (span.bold) style = style.copyWith(fontWeight: FontWeight.w700);
      if (span.italic) style = style.copyWith(fontStyle: FontStyle.italic);
      if (span.strike) {
        style = style.copyWith(
          decoration: TextDecoration.lineThrough,
          decorationColor: colors.textA10,
        );
      }
      if (span.code) {
        style = style.copyWith(
          fontFamily: 'monospace',
          fontSize: 13,
          color: colors.primaryA10,
          backgroundColor: colors.surfaceA10,
        );
      }
      if (span.mention != null) {
        style = style.copyWith(
          color: colors.primaryA0,
          fontWeight: FontWeight.w600,
          backgroundColor: colors.primaryA0.withOpacity(0.1),
        );
      }
      if (span.linkUrl != null) {
        style = style.copyWith(
          color: colors.primaryA10,
          decoration: TextDecoration.underline,
          decorationColor: colors.primaryA10,
        );
      }

      inlineChildren.add(TextSpan(text: span.text, style: style));
    }

    if (edited) {
      inlineChildren.add(TextSpan(
        text: '  (edited)',
        style: baseStyle.copyWith(
          fontSize: 11,
          color: colors.textA40,
          fontStyle: FontStyle.italic,
        ),
      ));
    }

    return Text.rich(
      TextSpan(children: inlineChildren),
      style: baseStyle,
    );
  }
}

class _CodeBlockWidget extends StatefulWidget {
  final _CodeBlock block;
  final dynamic colors;

  const _CodeBlockWidget({required this.block, required this.colors});

  @override
  State<_CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<_CodeBlockWidget> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: c.inputBgDarkest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.popupA10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: c.inputBorderBgDark,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.block.lang.isEmpty ? 'code' : widget.block.lang,
                  style: TextStyle(
                      fontSize: 12,
                      color: c.textA30,
                      fontFamily: 'Inter'),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: widget.block.code));
                    setState(() => _copied = true);
                    Future.delayed(const Duration(seconds: 2),
                        () { if (mounted) setState(() => _copied = false); });
                  },
                  child: Icon(
                    _copied ? Icons.check_rounded : Icons.content_copy_rounded,
                    size: 16,
                    color: c.textA30,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              widget.block.code.trimRight(),
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: c.textA0,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TwemojiWidget extends StatelessWidget {
  final String emoji;
  final double size;

  const _TwemojiWidget({required this.emoji, required this.size});

  @override
  Widget build(BuildContext context) {
    final url = _twemojiUrl(emoji);
    return SizedBox(
      width: size,
      height: size,
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Text(
          emoji,
          style: TextStyle(fontSize: size * 0.82),
        ),
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Text(emoji, style: TextStyle(fontSize: size * 0.82));
        },
      ),
    );
  }
}

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

class _ChatScreenState extends State<ChatScreen>
    with ThemeAware<ChatScreen> {
  final List<MessageModel> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  final _socketService = SocketService();
  final _authService = AuthService();

  String? _accessToken;
  String? _myUserId;
  bool _isLoading = true;
  bool _isPaginationLoading = false;
  bool _disposed = false;
  int _offset = 0;
  static const int _pageSize = 50;

  MessageModel? _replyingTo;

  MessageModel? _editingMsg;

  bool _hasText = false;

  String get _serverId => widget.server.id;
  String get _channelId => widget.channel.id;

  @override
  void initState() {
    super.initState();
    _init();
    _scrollController.addListener(_onScroll);
    _inputController.addListener(() {
      final has = _inputController.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channel.id != widget.channel.id ||
        oldWidget.server.id != widget.server.id) {
      _teardownListeners();
      setState(() {
        _messages.clear();
        _offset = 0;
        _isLoading = true;
        _replyingTo = null;
        _editingMsg = null;
      });
      _init();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _teardownListeners();
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _safe(VoidCallback fn) {
    if (!_disposed && mounted) setState(fn);
  }

  Future<void> _init() async {
    try {
      _accessToken = await _authService.getAccessToken();
    } catch (_) {}
    try {
      final u = UserService.cachedUser;
      if (u != null) _myUserId = u.id.toString();
    } catch (_) {}
    _setupListeners();
    _fetchMessages(offset: 0);
  }

  void _setupListeners() {
    _socketService.on('all_messages', _onAllMessages);
    _socketService.on('all_messages_nocache', _onAllMessages);
    _socketService.on('new_message', _onNewMessage);
    _socketService.on('message_deleted', _onMessageDeleted);
    _socketService.on('update_message', _onUpdateMessage);
  }

  void _teardownListeners() {
    _socketService.off('all_messages', _onAllMessages);
    _socketService.off('all_messages_nocache', _onAllMessages);
    _socketService.off('new_message', _onNewMessage);
    _socketService.off('message_deleted', _onMessageDeleted);
    _socketService.off('update_message', _onUpdateMessage);
  }

  void _fetchMessages({required int offset}) {
    if (_accessToken == null) return;
    _socketService.socket?.emit('get_messages', {
      'access_token': _accessToken,
      'server_id': _serverId,
      'channel_id': _channelId,
      'offset': offset,
    });
  }

  void _onAllMessages(dynamic data) {
    if (_disposed) return;
    final List<dynamic> raw =
        data is List ? data : (data as Map?)?['messages'] ?? [];
    final incoming = raw
        .map((e) {
          try {
            return MessageModel.fromJson(e as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<MessageModel>()
        .toList();

    final isPagination = _offset > 0;
    _safe(() {
      if (isPagination) {
        _messages.insertAll(0, incoming);
      } else {
        _messages
          ..clear()
          ..addAll(incoming);
      }
      _isLoading = false;
      _isPaginationLoading = false;
      _offset += incoming.length;
    });

    if (!isPagination) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _onNewMessage(dynamic data) {
    if (_disposed || data == null) return;
    try {
      final msg =
          MessageModel.fromJson(data as Map<String, dynamic>);
      if (msg.id.isEmpty) return;
      final wasAtBottom = _isAtBottom;
      _safe(() {
        _messages.removeWhere((m) => m.id == msg.id);
        _messages.add(msg);
        _offset++;
      });
      if (wasAtBottom) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (_) {}
  }

  void _onMessageDeleted(dynamic data) {
    if (_disposed || data == null) return;
    final id = (data is Map ? data['message_id'] : data)?.toString();
    if (id == null) return;
    _safe(() => _messages.removeWhere((m) => m.id == id));
  }

  void _onUpdateMessage(dynamic data) {
    if (_disposed || data == null) return;
    try {
      final updated =
          MessageModel.fromJson(data as Map<String, dynamic>);
      final idx = _messages.indexWhere((m) => m.id == updated.id);
      if (idx != -1) _safe(() => _messages[idx] = updated);
    } catch (_) {}
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 120 &&
        !_isPaginationLoading &&
        !_isLoading &&
        _offset >= _pageSize) {
      _safe(() => _isPaginationLoading = true);
      _fetchMessages(offset: _offset);
    }
  }

  bool get _isAtBottom {
    if (!_scrollController.hasClients) return true;
    final pos = _scrollController.position;
    return pos.maxScrollExtent - pos.pixels <= 80;
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty || _accessToken == null) return;

    if (_editingMsg != null) {
      _socketService.socket?.emit('edit_message', {
        'access_token': _accessToken,
        'message_id': _editingMsg!.id,
        'server_id': _serverId,
        'message': text,
      });
      _safe(() {
        _editingMsg = null;
        _replyingTo = null;
      });
    } else {
      final payload = <String, dynamic>{
        'access_token': _accessToken,
        'message': text,
        'server_id': _serverId,
        'channel_id': _channelId,
      };
      if (_replyingTo != null) {
        payload['parent_message_id'] = _replyingTo!.id;
      }
      _socketService.socket?.emit('send_message', payload);
      _safe(() => _replyingTo = null);
    }

    _inputController.clear();
    _inputFocus.requestFocus();
  }

  void _startReply(MessageModel msg) {
    _safe(() {
      _replyingTo = msg;
      _editingMsg = null;
    });
    _inputFocus.requestFocus();
  }

  void _startEdit(MessageModel msg) {
    _safe(() {
      _editingMsg = msg;
      _replyingTo = null;
    });
    _inputController.text = msg.message ?? '';
    _inputController.selection = TextSelection.collapsed(
        offset: _inputController.text.length);
    _inputFocus.requestFocus();
  }

  void _cancelEdit() {
    _safe(() => _editingMsg = null);
    _inputController.clear();
  }

  void _cancelReply() => _safe(() => _replyingTo = null);

  void _deleteMessage(MessageModel msg) {
    _socketService.socket?.emit('delete_message', {
      'access_token': _accessToken,
      'message_id': msg.id,
      'server_id': _serverId,
      'channel_id': _channelId,
    });
    _safe(() => _messages.removeWhere((m) => m.id == msg.id));
  }

  bool _shouldBeCompact(MessageModel msg, MessageModel? prev) {
    if (prev == null) return false;
    if (msg.parentMessageInfo != null) return false;
    if (prev.senderId != msg.senderId) return false;
    final prevTime = DateTime.tryParse(prev.createdAt);
    final currTime = DateTime.tryParse(msg.createdAt);
    if (prevTime == null || currTime == null) return false;
    return currTime.difference(prevTime).inMinutes < 10;
  }

  bool _shouldShowDateSep(MessageModel msg, MessageModel? prev) {
    if (prev == null) return false;
    final d1 = DateTime.tryParse(prev.createdAt)?.toLocal();
    final d2 = DateTime.tryParse(msg.createdAt)?.toLocal();
    if (d1 == null || d2 == null) return false;
    return d1.day != d2.day ||
        d1.month != d2.month ||
        d1.year != d2.year;
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors;

    return Scaffold(
      backgroundColor: colors.surfaceA0,
      body: Column(
        children: [
          _TopBar(
            channel: widget.channel,
            colors: colors,
            onMenuTap: widget.onShowSidebar,
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(colors.primaryA0),
                    ),
                  )
                : _messages.isEmpty
                    ? _EmptyState(colors: colors)
                    : Stack(
                        children: [
                          ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                            itemCount: _messages.length,
                            itemBuilder: (ctx, i) {
                              final msg = _messages[i];
                              final prev =
                                  i > 0 ? _messages[i - 1] : null;
                              final compact =
                                  _shouldBeCompact(msg, prev);
                              final showDate =
                                  _shouldShowDateSep(msg, prev);

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (showDate)
                                    _DateSep(
                                        timestamp: msg.createdAt,
                                        colors: colors),
                                  _SwipeToReply(
                                    onReply: () => _startReply(msg),
                                    child: _MessageRow(
                                      msg: msg,
                                      compact: compact,
                                      colors: colors,
                                      isMine: _myUserId != null &&
                                          msg.sentBy?.toString() == _myUserId,
                                      onReply: () => _startReply(msg),
                                      onEdit: () => _startEdit(msg),
                                      onDelete: () =>
                                          _deleteMessage(msg),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          if (_isPaginationLoading)
                            Positioned(
                              top: 8,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colors.popupA0,
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: Border.all(
                                        color: colors.popupA10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation(
                                                  colors.primaryA0),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Loading older messages…',
                                          style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12,
                                              color: colors.textA40)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
          ),
          _InputArea(
            controller: _inputController,
            focusNode: _inputFocus,
            colors: colors,
            channelName: widget.channel.name,
            hasText: _hasText,
            replyingTo: _replyingTo,
            editingMsg: _editingMsg,
            onSend: _sendMessage,
            onCancelReply: _cancelReply,
            onCancelEdit: _cancelEdit,
          ),
        ],
      ),
    );
  }
}

class _SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;

  const _SwipeToReply({required this.child, required this.onReply});

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply>
    with SingleTickerProviderStateMixin {
  double _dragX = 0;
  bool _triggered = false;
  late AnimationController _snapController;
  late Animation<double> _snapAnim;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _snapAnim = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _snapController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (d.delta.dx < 0) return;
    setState(() => _dragX = (_dragX + d.delta.dx).clamp(0.0, 72.0));
    if (_dragX >= 52 && !_triggered) {
      _triggered = true;
      HapticFeedback.lightImpact();
    }
  }

  void _onDragEnd(DragEndDetails d) {
    if (_triggered) {
      widget.onReply();
    }
    _triggered = false;
    _snapAnim = Tween<double>(begin: _dragX, end: 0).animate(
        CurvedAnimation(parent: _snapController, curve: Curves.easeOut));
    _snapController.forward(from: 0).then((_) {
      if (mounted) setState(() => _dragX = 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: AnimatedBuilder(
        animation: _snapController,
        builder: (ctx, child) {
          final offset = _snapController.isAnimating
              ? _snapAnim.value
              : _dragX;
          return Stack(
            children: [
              if (offset > 10)
                Positioned(
                  left: offset - 28,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Opacity(
                      opacity: (offset / 52).clamp(0.0, 1.0),
                      child: Icon(Icons.reply_rounded,
                          size: 22,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.7)),
                    ),
                  ),
                ),
              Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              ),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  final MessageModel msg;
  final bool compact;
  final dynamic colors;
  final bool isMine;
  final VoidCallback onReply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MessageRow({
    required this.msg,
    required this.compact,
    required this.colors,
    required this.isMine,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: Container(
        padding: EdgeInsets.only(
          top: compact ? 2 : 10,
          bottom: 2,
          left: 12,
          right: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 38,
              child: compact
                  ? const SizedBox(height: 2)
                  : SizedBox(
                      width: 30,
                      height: 30,
                      child: ClipOval(
                        child: Image.network(
                          msg.senderInfo.profilePicture,
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _AvatarFallback(
                            name: msg.senderInfo.effectiveName,
                            colors: colors,
                          ),
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (msg.parentMessageInfo != null)
                    _ReplyPreview(
                        info: msg.parentMessageInfo!, colors: colors),
                  if (!compact) _Header(msg: msg, colors: colors),
                  if (msg.message != null && msg.message!.isNotEmpty)
                    _MarkdownWidget(
                      text: msg.message!,
                      edited: msg.edited == 1,
                      colors: colors,
                    ),
                  if (msg.assets.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _AssetList(assets: msg.assets, colors: colors),
                    ),
                  if (msg.reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _ReactionsRow(
                          reactions: msg.reactions, colors: colors),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.popupA0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              decoration: BoxDecoration(
                color: colors.popupA20,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _OptionTile(
              icon: Icons.reply_rounded,
              label: 'Reply',
              colors: colors,
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),
            if (isMine) ...[
              _OptionTile(
                icon: Icons.edit_rounded,
                label: 'Edit',
                colors: colors,
                onTap: () {
                  Navigator.pop(context);
                  onEdit();
                },
              ),
              _OptionTile(
                icon: Icons.delete_rounded,
                label: 'Delete',
                colors: colors,
                danger: true,
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
            ],
            _OptionTile(
              icon: Icons.content_copy_rounded,
              label: 'Copy text',
              colors: colors,
              onTap: () {
                Navigator.pop(context);
                if (msg.message != null) {
                  Clipboard.setData(ClipboardData(text: msg.message!));
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic colors;
  final bool danger;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? colors.dangerA10 : colors.textA0;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final MessageModel msg;
  final dynamic colors;

  const _Header({required this.msg, required this.colors});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(msg.createdAt)?.toLocal();
    final timeStr = date != null
        ? '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            msg.senderInfo.effectiveName,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textA0,
            ),
          ),
          if (msg.botMessage == 1) ...[
            const SizedBox(width: 5),
            _BotTag(colors: colors),
          ],
          if (msg.senderInfo.premium) ...[
            const SizedBox(width: 4),
            Icon(Icons.star_rounded, size: 12, color: colors.primaryA0),
          ],
          const SizedBox(width: 6),
          Text(
            timeStr,
            style: TextStyle(
                fontFamily: 'Inter', fontSize: 11, color: colors.textA40),
          ),
        ],
      ),
    );
  }
}

class _BotTag extends StatelessWidget {
  final dynamic colors;
  const _BotTag({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: colors.primaryA0.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: colors.primaryA0.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 10, color: colors.primaryA0),
          const SizedBox(width: 2),
          Text('BOT',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: colors.primaryA0)),
        ],
      ),
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  final ParentMessageInfo info;
  final dynamic colors;

  const _ReplyPreview({required this.info, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(Icons.reply_rounded, size: 13, color: colors.textA40),
          const SizedBox(width: 4),
          Text(
            '@${info.username}',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textA30),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              info.messagePreview,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: colors.textA40),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String name;
  final dynamic colors;

  const _AvatarFallback({required this.name, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      color: colors.surfaceA20,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.textA20),
        ),
      ),
    );
  }
}

class _AssetList extends StatelessWidget {
  final List<MessageAsset> assets;
  final dynamic colors;

  const _AssetList({required this.assets, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: assets.map((a) => _AssetChip(asset: a, colors: colors)).toList(),
    );
  }
}

class _AssetChip extends StatelessWidget {
  final MessageAsset asset;
  final dynamic colors;

  const _AssetChip({required this.asset, required this.colors});

  @override
  Widget build(BuildContext context) {
    if (asset.isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          'https://chat.wokki20.nl/uploads/messages/${Uri.encodeComponent(asset.savedName)}',
          width: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fileFallback(context),
        ),
      );
    }
    return _fileFallback(context);
  }

  Widget _fileFallback(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.popupA0,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.popupA10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_file_rounded, size: 14, color: colors.textA30),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              asset.originalName,
              style: TextStyle(
                  fontFamily: 'Inter', fontSize: 13, color: colors.textA20),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionsRow extends StatelessWidget {
  final List<MessageReaction> reactions;
  final dynamic colors;

  const _ReactionsRow({required this.reactions, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: reactions.map((r) {
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: r.own
                ? colors.primaryA0.withOpacity(0.15)
                : colors.popupA10,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: r.own
                  ? colors.primaryA0.withOpacity(0.5)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TwemojiWidget(emoji: r.emoji, size: 14),
              const SizedBox(width: 4),
              Text(
                '${r.count}',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: r.own ? colors.primaryA0 : colors.textA30),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DateSep extends StatelessWidget {
  final String timestamp;
  final dynamic colors;

  const _DateSep({required this.timestamp, required this.colors});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(timestamp)?.toLocal();
    final label = date == null ? '' : _fmt(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Row(
        children: [
          Expanded(
              child: Divider(color: colors.popupA10, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textA40)),
          ),
          Expanded(
              child: Divider(color: colors.popupA10, height: 1)),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const m = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _EmptyState extends StatelessWidget {
  final dynamic colors;
  const _EmptyState({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 48, color: colors.textA40),
          const SizedBox(height: 12),
          Text('No messages yet',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textA20)),
          const SizedBox(height: 4),
          Text('Be the first to say something!',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: colors.textA40)),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final ChannelModel channel;
  final dynamic colors;
  final VoidCallback onMenuTap;

  const _TopBar({
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
              bottom: BorderSide(color: colors.popupA10, width: 1)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onMenuTap,
              icon: Icon(Icons.menu_rounded,
                  color: colors.textA20, size: 22),
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
                    color: colors.textA0),
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

class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final dynamic colors;
  final String channelName;
  final bool hasText;
  final MessageModel? replyingTo;
  final MessageModel? editingMsg;
  final VoidCallback onSend;
  final VoidCallback onCancelReply;
  final VoidCallback onCancelEdit;

  const _InputArea({
    required this.controller,
    required this.focusNode,
    required this.colors,
    required this.channelName,
    required this.hasText,
    required this.replyingTo,
    required this.editingMsg,
    required this.onSend,
    required this.onCancelReply,
    required this.onCancelEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.popupA0,
        border:
            Border(top: BorderSide(color: colors.popupA10, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyingTo != null)
            _ReplyBar(
              msg: replyingTo!,
              colors: colors,
              onCancel: onCancelReply,
            ),
          if (editingMsg != null)
            _EditBar(colors: colors, onCancel: onCancelEdit),
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                        minHeight: 42, maxHeight: 160),
                    decoration: BoxDecoration(
                      color: colors.inputBgDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: colors.inputBorderBgDarkest),
                    ),
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: colors.textA0,
                          height: 1.4),
                      decoration: InputDecoration(
                        hintText: editingMsg != null
                            ? 'Editing message…'
                            : 'Message #$channelName',
                        hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: colors.textA40),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedOpacity(
                  opacity: hasText ? 1.0 : 0.38,
                  duration: const Duration(milliseconds: 150),
                  child: GestureDetector(
                    onTap: hasText ? onSend : null,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: hasText
                            ? colors.primaryA0
                            : colors.surfaceA20,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        editingMsg != null
                            ? Icons.check_rounded
                            : Icons.send_rounded,
                        size: 18,
                        color: hasText
                            ? colors.textWhiteA0
                            : colors.textA40,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyBar extends StatelessWidget {
  final MessageModel msg;
  final dynamic colors;
  final VoidCallback onCancel;

  const _ReplyBar(
      {required this.msg, required this.colors, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: colors.inputBorderBgDark)),
      ),
      child: Row(
        children: [
          Icon(Icons.reply_rounded, size: 16, color: colors.primaryA0),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${msg.senderInfo.effectiveName}',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.primaryA0),
                ),
                if (msg.message != null && msg.message!.isNotEmpty)
                  Text(
                    msg.message!,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: colors.textA40),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child:
                Icon(Icons.close_rounded, size: 18, color: colors.textA30),
          ),
        ],
      ),
    );
  }
}

class _EditBar extends StatelessWidget {
  final dynamic colors;
  final VoidCallback onCancel;

  const _EditBar({required this.colors, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: colors.inputBorderBgDark)),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_rounded, size: 16, color: colors.primaryA0),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Editing message · press ✓ to save',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.primaryA0),
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child:
                Icon(Icons.close_rounded, size: 18, color: colors.textA30),
          ),
        ],
      ),
    );
  }
}