class UserModel {
  final int id;
  final String username;
  final String? displayName;
  final String? email;
  final String? bio;
  final String? status;
  final String? avatar;
  final String? banner;
  final String? accentColor;
  final String? primaryColor;
  final bool premium;
  final bool staff;
  final bool developer;
  final bool bot;
  final List<dynamic> tags;
  final List<dynamic> connections;
  final String? createdAt;

  const UserModel({
    required this.id,
    required this.username,
    this.displayName,
    this.email,
    this.bio,
    this.status,
    this.avatar,
    this.banner,
    this.accentColor,
    this.primaryColor,
    this.premium = false,
    this.staff = false,
    this.developer = false,
    this.bot = false,
    this.tags = const [],
    this.connections = const [],
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      displayName: json['display_name'],
      email: json['email'],
      bio: json['bio'],
      status: json['status'],
      avatar: json['avatar'],
      banner: json['banner'],
      accentColor: json['accent_color'],
      primaryColor: json['primary_color'],
      premium: json['premium'] == true,
      staff: json['staff'] == true,
      developer: json['developer'] == true,
      bot: json['bot'] == true,
      tags: json['tags'] ?? [],
      connections: json['connections'] ?? [],
      createdAt: json['created_at'],
    );
  }

  String get effectiveName => displayName?.isNotEmpty == true ? displayName! : username;
}