import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserInfoModel {
  final int? id;
  final String? username;
  final String? fullname;
  final String? avatarUrl;
  final bool? follow;
  final int? followersCount;
  final int? followingsCount;
  final int? reputationScore;
  final String? badge;
  final bool? canCreatePost;

  UserInfoModel({
    this.id,
    this.username,
    this.fullname,
    this.avatarUrl,
    this.follow,
    this.followersCount,
    this.followingsCount,
    this.reputationScore,
    this.badge,
    this.canCreatePost,
  });

  // Chuyển từ JSON của API sang Object Dart
  factory UserInfoModel.fromJson(Map<String, dynamic> json) {
    final score = json['reputationScore'] as int? ?? 100;
    return UserInfoModel(
      id: json['id'] as int?,
      username: json['username'] as String?,
      fullname: (json['fullname'] ?? json['fullName']) as String?,
      avatarUrl: json['avatarUrl'] as String?,
      follow: json['follow'] as bool?,
      followersCount: json['followersCount'] as int?,
      followingsCount: json['followingsCount'] as int?,
      reputationScore: score,
      badge: json['badge'] as String? ?? 'Người dẫn đường',
      canCreatePost: json['canCreatePost'] as bool? ?? (score >= 80),
    );
  }

  // Chuyển từ Object Dart sang JSON (Dự phòng khi cần gửi data đi)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (fullname != null) 'fullname': fullname,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (follow != null) 'follow': follow,
      if (followersCount != null) 'followersCount': followersCount,
      if (followingsCount != null) 'followingsCount': followingsCount,
      if (reputationScore != null) 'reputationScore': reputationScore,
      if (badge != null) 'badge': badge,
      if (canCreatePost != null) 'canCreatePost': canCreatePost,
    };
  }

  /// Hàm hỗ trợ lấy link ảnh avatar đầy đủ (Giống hệt cách làm bên TrafficPostModel)
  String? get fullAvatarUrl {
    if (avatarUrl == null || avatarUrl!.isEmpty) return null;

    // Nếu Backend đã trả về URL đầy đủ (chứa http/https), thì dùng luôn
    if (avatarUrl!.startsWith('http://') || avatarUrl!.startsWith('https://')) {
      return avatarUrl;
    }

    // Nếu Backend chỉ trả về tên file (VD: "avatar_123.jpg"), thì ghép với BASE_URL
    final baseUrl = dotenv.env['BASE_URL'] ?? '';
    return '$baseUrl/uploads/$avatarUrl';
  }

  UserInfoModel copyWith({
    int? id,
    String? username,
    String? fullname,
    String? avatarUrl,
    bool? follow,
    int? followersCount,
    int? followingsCount,
    int? reputationScore,
    String? badge,
    bool? canCreatePost,
  }) {
    return UserInfoModel(
      id: id ?? this.id,
      username: username ?? this.username,
      fullname: fullname ?? this.fullname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      follow: follow ?? this.follow,
      followersCount: followersCount ?? this.followersCount,
      followingsCount: followingsCount ?? this.followingsCount,
      reputationScore: reputationScore ?? this.reputationScore,
      badge: badge ?? this.badge,
      canCreatePost: canCreatePost ?? this.canCreatePost,
    );
  }
}