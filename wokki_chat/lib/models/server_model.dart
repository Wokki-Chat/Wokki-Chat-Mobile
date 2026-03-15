class ChannelModel {
  final String id;
  final String name;
  final String type;
  final String createdAt;
  final String updatedAt;
  final int isDefault;
  final int? index;
  final String groupId;

  const ChannelModel({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.isDefault,
    this.index,
    required this.groupId,
  });

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      isDefault: json['is_default'] ?? 0,
      index: json['index'],
      groupId: json['group_id'] ?? '',
    );
  }
}

class ChannelGroupModel {
  final String id;
  final String name;
  final String createdAt;
  final String updatedAt;
  final int? index;
  final List<ChannelModel> channels;

  const ChannelGroupModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.index,
    required this.channels,
  });

  factory ChannelGroupModel.fromJson(Map<String, dynamic> json) {
    return ChannelGroupModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      index: json['index'],
      channels: (json['channels'] as List<dynamic>?)
              ?.map((c) => ChannelModel.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ServerModel {
  final String id;
  final String name;
  final String? description;
  final String? image;
  final int createdBy;
  final String createdAt;
  final String serverType;
  final int? position;
  final String joinedAt;
  final List<ChannelGroupModel> channelGroups;

  const ServerModel({
    required this.id,
    required this.name,
    this.description,
    this.image,
    required this.createdBy,
    required this.createdAt,
    required this.serverType,
    this.position,
    required this.joinedAt,
    required this.channelGroups,
  });

  factory ServerModel.fromJson(Map<String, dynamic> json) {
    return ServerModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      image: json['image'],
      createdBy: json['created_by'] ?? 0,
      createdAt: json['created_at'] ?? '',
      serverType: json['server_type'] ?? 'normal',
      position: json['position'],
      joinedAt: json['joined_at'] ?? '',
      channelGroups: (json['channel_groups'] as List<dynamic>?)
              ?.map((g) => ChannelGroupModel.fromJson(g as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}