import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final bool isGuest;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.isGuest = false,
    required this.createdAt,
  });

  static UserModel guest() {
    return UserModel(
      id: 'guest_user',
      name: 'Guest User',
      email: 'guest@offline.local',
      bio: 'Crushing daily goals offline ✨',
      isGuest: true,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'isGuest': isGuest ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: (map['id'] as String?) ?? 'user_1',
      name: (map['name'] as String?) ?? 'Productive User',
      email: (map['email'] as String?) ?? '',
      avatarUrl: map['avatarUrl'] as String?,
      bio: (map['bio'] as String?) ?? 'Focus on progress, not perfection 🎯',
      isGuest: (map['isGuest'] as int? ?? (map['isGuest'] == true ? 1 : 0)) == 1,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? bio,
    bool? isGuest,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      isGuest: isGuest ?? this.isGuest,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
