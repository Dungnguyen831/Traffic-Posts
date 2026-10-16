class ProfileRequest {
  int? id;
  String? username;
  String? fullname;
  String? email;
  String? province;
  String? phoneNumber; 
  String? avatarUrl;
  String? relativePhone;
  int? roleId;
  int? reputationScore;
  String? badge;
  bool? canCreatePost;

  ProfileRequest({
    this.id,
    this.username,
    this.fullname,
    this.email,
    this.province,
    this.phoneNumber,
    this.avatarUrl,
    this.relativePhone,
    this.roleId,
    this.reputationScore,
    this.badge,
    this.canCreatePost,
  });

  factory ProfileRequest.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : (json['data'] is Map
            ? Map<String, dynamic>.from(json['data'] as Map)
            : json);

    final scoreRaw = data['reputationScore'];
    final score = scoreRaw is num
        ? scoreRaw.toInt()
        : (scoreRaw is String ? int.tryParse(scoreRaw) ?? 100 : 100);

    return ProfileRequest(
      id: data['id'] is num
          ? (data['id'] as num).toInt()
          : (data['id'] is String ? int.tryParse(data['id'] as String) : null),
      username: data['username'] as String?,
      fullname: (data['fullname'] ?? data['fullName']) as String?,
      email: data['email'] as String?,
      province: data['province'] as String?,
      phoneNumber: (data['phoneNumber'] ?? data['phone']) as String?,
      avatarUrl: data['avatarUrl'] as String?,
      relativePhone: data['relativePhone'] as String?,
      roleId: data['roleId'] is num ? (data['roleId'] as num).toInt() : null,
      reputationScore: score,
      badge: data['badge'] as String? ?? 'Người dẫn đường',
      canCreatePost: data['canCreatePost'] as bool? ?? (score >= 80),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'fullname': fullname,
      'email': email,
      'province': province,
    };

    // Kiểm tra an toàn: Chỉ đóng gói SĐT nếu nó không rỗng
    if (phoneNumber != null && phoneNumber!.trim().isNotEmpty) {
      data['phoneNumber'] = phoneNumber;
    }

    // Tương tự với SĐT người thân
    if (relativePhone != null && relativePhone!.trim().isNotEmpty) {
      data['relativePhone'] = relativePhone;
    }

    return data;
  }
}