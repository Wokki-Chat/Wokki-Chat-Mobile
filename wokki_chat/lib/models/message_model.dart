class SenderInfo {
  final String username;
  final String? displayName;
  final String profilePicture;
  final bool premium;
  final int staff;

  const SenderInfo({
    required this.username,
    required this.displayName,
    required this.profilePicture,
    required this.premium,
    required this.staff,
  });

  factory SenderInfo.fromJson(Map<String, dynamic> json) {
    return SenderInfo(
      username: json['username'] ?? '',
      displayName: json['display_name'],
      profilePicture: json['profile_picture'] ?? '',
      premium: json['premium'] == true,
      staff: (json['staff'] as num?)?.toInt() ?? 0,
    );
  }

  String get effectiveName =>
      displayName != null && displayName!.isNotEmpty ? displayName! : username;
}

class MessageAsset {
  final String savedName;
  final String originalName;

  const MessageAsset({required this.savedName, required this.originalName});

  factory MessageAsset.fromJson(Map<String, dynamic> json) {
    return MessageAsset(
      savedName: json['savedName'] ?? json['saved_name'] ?? '',
      originalName: json['originalName'] ?? json['original_name'] ?? '',
    );
  }

  String get ext {
    final parts = savedName.toLowerCase().split('.');
    return parts.isNotEmpty ? parts.last : '';
  }

  bool get isImage => ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'].contains(ext);
  bool get isVideo => ['mp4', 'webm', 'ogg'].contains(ext);
  bool get isAudio => ['mp3', 'wav'].contains(ext);
}

class MessageReaction {
  final String emoji;
  final int count;
  final bool own;

  const MessageReaction({
    required this.emoji,
    required this.count,
    required this.own,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      emoji: json['emoji'] ?? json['reaction'] ?? '',
      count: (json['count'] as num?)?.toInt() ?? 1,
      own: json['own'] == true,
    );
  }
}

class ParentMessageInfo {
  final String messageId;
  final String username;
  final String messagePreview;

  const ParentMessageInfo({
    required this.messageId,
    required this.username,
    required this.messagePreview,
  });

  factory ParentMessageInfo.fromJson(Map<String, dynamic> json) {
    return ParentMessageInfo(
      messageId: json['message_id']?.toString() ?? '',
      username: json['username'] ?? '',
      messagePreview: json['message_preview'] ?? '',
    );
  }
}

class MessageModel {
  final String id;
  final String? message;
  final String createdAt;
  final String? updatedAt;
  final int botMessage;
  final SenderInfo senderInfo;
  final int? sentBy;
  final int? sentByBot;
  final int edited;
  final List<MessageAsset> assets;
  final List<MessageReaction> reactions;
  final ParentMessageInfo? parentMessageInfo;

  const MessageModel({
    required this.id,
    this.message,
    required this.createdAt,
    this.updatedAt,
    required this.botMessage,
    required this.senderInfo,
    this.sentBy,
    this.sentByBot,
    required this.edited,
    required this.assets,
    required this.reactions,
    this.parentMessageInfo,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    List<MessageReaction> reactions = [];
    final rawReactions = json['reactions'];
    if (rawReactions is List) {
      final grouped = <String, List<dynamic>>{};
      for (final r in rawReactions) {
        final key = (r['reaction'] ?? r['emoji'] ?? '').toString();
        if (key.isEmpty) continue;
        grouped.putIfAbsent(key, () => []).add(r);
      }
      for (final entry in grouped.entries) {
        final isOwn = entry.value.any((r) => r['own'] == true);
        reactions.add(MessageReaction(
          emoji: entry.key,
          count: entry.value.length,
          own: isOwn,
        ));
      }
    }

    return MessageModel(
      id: json['id']?.toString() ?? '',
      message: json['message'] as String?,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] as String?,
      botMessage: (json['bot_message'] as num?)?.toInt() ?? 0,
      senderInfo: SenderInfo.fromJson(
          json['sender_info'] as Map<String, dynamic>? ?? {}),
      sentBy: (json['sent_by'] as num?)?.toInt(),
      sentByBot: (json['sent_by_bot'] as num?)?.toInt(),
      edited: (json['edited'] as num?)?.toInt() ?? 0,
      assets: (json['assets'] as List<dynamic>?)
              ?.map((a) => MessageAsset.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      reactions: reactions,
      parentMessageInfo: json['parent_message_info'] != null
          ? ParentMessageInfo.fromJson(
              json['parent_message_info'] as Map<String, dynamic>)
          : null,
    );
  }

  int get senderId => sentBy ?? sentByBot ?? 0;
}