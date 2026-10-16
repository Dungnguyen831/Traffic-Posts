class LoginResponse {
  final int? id;
  final String? token;
  final String? username;
  final String? fullname;
  final String? province;
  final String? relativePhone;
  final String? phoneNumber;
  final int? reputationScore;
  final String? badge;
  final bool? canCreatePost;

  LoginResponse({
    this.id,
    this.token,
    this.username,
    this.fullname,
    this.province,
    this.relativePhone,
    this.phoneNumber,
    this.reputationScore,
    this.badge,
    this.canCreatePost,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final score = json['reputationScore'] as int? ?? 100;
    return LoginResponse(
      id: json['id'] as int?,
      token: json['token'] as String?,
      username: json['username'] as String?,
      fullname: (json['fullname'] ?? json['fullName']) as String?,
      province: json['province'] as String?,
      relativePhone: json['relativePhone'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      reputationScore: score,
      badge: json['badge'] as String? ?? 'Người dẫn đường',
      canCreatePost: json['canCreatePost'] as bool? ?? (score >= 80),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'token': token,
      'username': username,
      'fullname': fullname,
      'province': province,
      'relativePhone': relativePhone,
      'phoneNumber': phoneNumber,
      'reputationScore': reputationScore,
      'badge': badge,
      'canCreatePost': canCreatePost,
    };
  }
}
