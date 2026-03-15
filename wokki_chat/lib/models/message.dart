class Message {
  final String id;
  final String message;
  final String createdAt;
  final String? sentBy;
  final String? sentByBot;
  final int edited;
  final SenderInfo senderInfo;
  final String? embed;
  final ParentMessageInfo? parentMessageInfo;
  final CommandInfo? commandInfo;
  final List<Asset>? assets;
  final List<Reaction>? reactions;
  final int botMessage;

  Message({
    required this.id,
    required this.message,
    required this.createdAt,
    this.sentBy,
    this.sentByBot,
    required this.edited,
    required this.senderInfo,
    this.embed,
    this.parentMessageInfo,
    this.commandInfo,
    this.assets,
    this.reactions,
    required this.botMessage,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      sentBy: json['sent_by']?.toString(),
      sentByBot: json['sent_by_bot']?.toString(),
      edited: json['edited'] ?? 0,
      senderInfo: SenderInfo.fromJson(json['sender_info'] ?? {}),
      embed: json['embed']?.toString(),
      parentMessageInfo: json['parent_message_info'] != null
          ? ParentMessageInfo.fromJson(json['parent_message_info'])
          : null,
      commandInfo: json['command_info'] != null
          ? CommandInfo.fromJson(json['command_info'])
          : null,
      assets: json['assets'] != null
          ? (json['assets'] as List).map((a) => Asset.fromJson(a)).toList()
          : null,
      reactions: json['reactions'] != null
          ? (json['reactions'] as List).map((r) => Reaction.fromJson(r)).toList()
          : null,
      botMessage: json['bot_message'] ?? 0,
    );
  }

  String get senderId => sentBy ?? sentByBot ?? '';
}

class SenderInfo {
  final String username;
  final String? displayName;
  final String profilePicture;
  final bool premium;
  final int staff;

  SenderInfo({
    required this.username,
    this.displayName,
    required this.profilePicture,
    required this.premium,
    required this.staff,
  });

  factory SenderInfo.fromJson(Map<String, dynamic> json) {
    return SenderInfo(
      username: json['username']?.toString() ?? '',
      displayName: json['display_name']?.toString(),
      profilePicture: json['profile_picture']?.toString() ?? '',
      premium: json['premium'] == true,
      staff: json['staff'] ?? 0,
    );
  }
}

class ParentMessageInfo {
  final String messageId;
  final String username;
  final String messagePreview;

  ParentMessageInfo({
    required this.messageId,
    required this.username,
    required this.messagePreview,
  });

  factory ParentMessageInfo.fromJson(Map<String, dynamic> json) {
    return ParentMessageInfo(
      messageId: json['message_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      messagePreview: json['message_preview']?.toString() ?? '',
    );
  }
}

class CommandInfo {
  final String? username;
  final String? command;

  CommandInfo({
    this.username,
    this.command,
  });

  factory CommandInfo.fromJson(Map<String, dynamic> json) {
    return CommandInfo(
      username: json['username']?.toString(),
      command: json['command']?.toString(),
    );
  }
}

class Asset {
  final String savedName;
  final String originalName;

  Asset({
    required this.savedName,
    required this.originalName,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      savedName: json['savedName']?.toString() ?? '',
      originalName: json['originalName']?.toString() ?? '',
    );
  }

  String get assetType {
    final parts = savedName.toLowerCase().split('.');
    
    if (parts.length >= 3 && parts[parts.length - 1] == 'pfp' &&
        ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'].contains(parts[parts.length - 2])) {
      return 'profile_picture';
    }
    
    final ext = parts.last;
    if (['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'].contains(ext)) return 'image';
    if (['mp4', 'webm', 'ogg'].contains(ext)) return 'video';
    if (['mp3', 'wav', 'ogg'].contains(ext)) return 'audio';
    if (['pdf', 'txt'].contains(ext)) return ext;
    return 'other';
  }

  String get url {
    if (assetType == 'profile_picture') {
      return '/uploads/profile-pictures/${Uri.encodeComponent(savedName.substring(0, savedName.length - 4))}';
    }
    return '/uploads/messages/${Uri.encodeComponent(savedName)}';
  }
}

class Reaction {
  final String reaction;
  final String userId;
  final bool superReaction;

  Reaction({
    required this.reaction,
    required this.userId,
    required this.superReaction,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      reaction: json['reaction']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      superReaction: json['super_reaction'] == true,
    );
  }
}