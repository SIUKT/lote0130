import 'package:isar/isar.dart';

part 'profile.g.dart';

@collection
class Profile {
  Id id = Isar.autoIncrement;

  String? supabaseId;
  String? email;

  String? username;
  String? avatarUrl;
  DateTime? updatedAt;
  DateTime? createdAt;

  List<String>? tags;
  List<String>? languageCodes;

  Profile({
    this.supabaseId,
    this.email,
    this.username,
    this.avatarUrl,
    DateTime? updatedAt,
    DateTime? createdAt,
    this.tags,
    List<String>?languageCodes,
  })  : updatedAt = updatedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        languageCodes = languageCodes ?? ['zh','en'];

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      supabaseId: json['id'],
      email: json['email'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      tags: List<String>.from(json['tags']),
      languageCodes: List<String>.from(json['language_codes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': supabaseId,
      'email': email,
      'username': username,
      'avatar_url': avatarUrl,
      'updated_at': updatedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'tags': tags,
      'language_codes': languageCodes,
    };
  }
}
