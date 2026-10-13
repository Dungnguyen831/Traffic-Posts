import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserInfoModel {
  final int? id;
  final String? fullname;
  final String? avatarUrl;
  final bool? follow;
  final int? followersCount;
  final int? followingsCount;

  UserInfoModel({
    this.id,
    this.fullname,
    this.avatarUrl,
    this.follow,
    this.followersCount,
    this.followingsCount,
  });

  // Chuyển từ JSON của API sang Object Dart
  factory UserInfoModel.fromJson(Map<String, dynamic> json) {
    return UserInfoModel(
      id: json['id'] as int?,
      fullname: json['fullname'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      follow: json['follow'] as bool?,
      followersCount: json['followersCount'] as int?,
      followingsCount: json['followingsCount'] as int?,
    );
  }

  // Chuyển từ Object Dart sang JSON (Dự phòng khi cần gửi data đi)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (fullname != null) 'fullname': fullname,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (follow != null) 'follow': follow,
      if (followersCount != null) 'followersCount': followersCount,
      if (followingsCount != null) 'followingsCount': followingsCount,
    };
  }

  /// Hàm hỗ trợ lấy link ảnh avatar đầy đủ (Giống hệt cách làm bên TrafficPostModel)
  String? get fullAvatarUrl {
    if (avatarUrl == null || avatarUrl!.isEmpty) return null;

    // Nếu Backend đã trả về URL đầy đủ (chứa http/https) hoặc đường dẫn assets, thì dùng luôn
    if (avatarUrl!.startsWith('http://') ||
        avatarUrl!.startsWith('https://') ||
        avatarUrl!.startsWith('assets/')) {
      return avatarUrl;
    }

    // Nếu Backend chỉ trả về tên file (VD: "avatar_123.jpg"), thì ghép với BASE_URL
    final baseUrl = dotenv.env['BASE_URL'] ?? '';
    return '$baseUrl/uploads/$avatarUrl';
  }

  // Dán vào bên trong class UserInfoModel nhé
  UserInfoModel copyWith({
    int? id,
    String? fullname,
    String? avatarUrl,
    bool? follow,
    int? followersCount,
    int? followingsCount,
  }) {
    return UserInfoModel(
      id: id ?? this.id,
      fullname: fullname ?? this.fullname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      follow: follow ?? this.follow,
      followersCount: followersCount ?? this.followersCount,
      followingsCount: followingsCount ?? this.followingsCount,
    );
  }
}