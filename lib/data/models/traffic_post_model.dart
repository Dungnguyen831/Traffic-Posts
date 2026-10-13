import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'location_model.dart';

class TrafficPostModel {
  final String? id;
  final String? userId;
  final String? type;
  final String? content;
  final LocationModel? location;
  final String? status;
  final DateTime? timestamp;
  final String? userName;
  final String? avatarUrl;
  final List<String>? imageUrls;
  final int? likes;
  final bool? isLiked;
  final List<String>? hashtags;
  final bool? isFollowedByCurrentUser;

  TrafficPostModel({
    this.id,
    this.userId,
    this.type,
    this.content,
    this.location,
    this.status,
    this.timestamp,
    this.userName,
    this.avatarUrl,
    this.imageUrls,
    this.likes,
    this.isLiked,
    this.hashtags,
    this.isFollowedByCurrentUser,
  });

  factory TrafficPostModel.fromJson(Map<String, dynamic> json) {
    // Handle nested user object
    final user = json['user'] as Map<String, dynamic>?;

    return TrafficPostModel(
      id: json['id']?.toString(),
      userId: user?['id']?.toString() ?? json['userId']?.toString(),
      type: json['type'] as String?,
      content: json['content'] as String?,
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      userName: user?['fullname'] as String? ?? json['userName'] as String?,
      avatarUrl: user?['avatarUrl'] as String? ?? json['avatarUrl'] as String?,
      isFollowedByCurrentUser:
          json['isFollowedByCurrentUser'] as bool? ?? user?['follow'] as bool?,
      imageUrls: json['images'] != null
          ? List<String>.from(json['images'] as List)
          : (json['imageUrls'] != null
                ? List<String>.from(json['imageUrls'] as List)
                : null),
      likes: json['likeTotal'] as int? ?? json['likes'] as int?,
      isLiked:
          json['isLikedByCurrentUser'] as bool? ?? json['isLiked'] as bool?,
      hashtags: json['hashtags'] != null
          ? List<String>.from(json['hashtags'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'userId': userId,
      if (type != null) 'type': type,
      if (content != null) 'content': content,
      if (location != null) 'location': location!.toJson(),
      if (status != null) 'status': status,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      if (userName != null) 'userName': userName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (imageUrls != null) 'imageUrls': imageUrls,
      if (likes != null) 'likes': likes,
      if (isLiked != null) 'isLiked': isLiked,
      if (hashtags != null) 'hashtags': hashtags,
      if (isFollowedByCurrentUser != null)
        'isFollowedByCurrentUser': isFollowedByCurrentUser,
    };
  }

  /// Build full image URL from filename
  String? getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;

    // Nếu đã là URL đầy đủ hoặc đường dẫn assets, return luôn
    if (imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://') ||
        imageUrl.startsWith('assets/')) {
      return imageUrl;
    }

    // Thêm base URL
    final baseUrl = dotenv.env['BASE_URL'] ?? '';
    return '$baseUrl/uploads/$imageUrl';
  }

  /// Get full image URLs list
  List<String>? get fullImageUrls {
    if (imageUrls == null || imageUrls!.isEmpty) return null;
    return imageUrls!.map((url) => getFullImageUrl(url) ?? url).toList();
  }

  /// Get full avatar URL
  String? get fullAvatarUrl {
    if (avatarUrl == null || avatarUrl?.isEmpty == true) return null;

    // Nếu đã là URL đầy đủ hoặc đường dẫn assets, return luôn
    if (avatarUrl!.startsWith('http://') ||
        avatarUrl!.startsWith('https://') ||
        avatarUrl!.startsWith('assets/')) {
      return avatarUrl;
    }

    // Thêm base URL
    final baseUrl = dotenv.env['BASE_URL'] ?? '';
    return '$baseUrl/uploads/$avatarUrl';
  }

  TrafficPostModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? content,
    LocationModel? location,
    String? status,
    DateTime? timestamp,
    String? userName,
    String? avatarUrl,
    List<String>? imageUrls,
    int? likes,
    bool? isLiked,
    List<String>? hashtags,
    bool? isFollowedByCurrentUser,
  }) {
    return TrafficPostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      content: content ?? this.content,
      location: location ?? this.location,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      hashtags: hashtags ?? this.hashtags,
      isFollowedByCurrentUser:
          isFollowedByCurrentUser ?? this.isFollowedByCurrentUser,
    );
  }
}
