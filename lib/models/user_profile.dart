import 'package:uuid/uuid.dart';

class UserProfile {
  final String id;
  final String name;
  final String? avatarPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.name,
    this.avatarPath,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.create({required String name, String? avatarPath}) {
    final now = DateTime.now();
    return UserProfile(
      id: const Uuid().v4(),
      name: name,
      avatarPath: avatarPath,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      avatarPath: map['avatar_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar_path': avatarPath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({String? name, String? avatarPath}) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
