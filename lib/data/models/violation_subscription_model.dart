class ViolationSubscription {
  final int? id;
  final String licensePlate;
  final bool enabled;

  ViolationSubscription({
    this.id,
    required this.licensePlate,
    this.enabled = true,
  });

  /// Chuẩn hóa chuỗi biển số xe:
  /// Viết hoa, loại bỏ khoảng trắng, dấu gạch ngang và dấu chấm.
  /// Ví dụ: "51C - 918.20" -> "51C91820"
  static String normalizePlate(String rawPlate) {
    return rawPlate.trim().toUpperCase().replaceAll(RegExp(r'[\s\.\-]'), '');
  }

  /// Kiểm tra định dạng biển số xe Việt Nam (7 đến 10 ký tự: mã tỉnh + sê-ri + 4-5 chữ số)
  static bool isValidPlate(String rawPlate) {
    final normalized = normalizePlate(rawPlate);
    if (normalized.length < 6 || normalized.length > 10) return false;
    final regex = RegExp(r'^[0-9]{2}[A-Z0-9]{1,3}[0-9]{4,5}$');
    return regex.hasMatch(normalized);
  }

  /// Định dạng hiển thị đẹp mắt (VD: 51C-918.20 hoặc 29B1-123.45)
  String get formattedPlate {
    final clean = normalizePlate(licensePlate);
    if (clean.length == 8) {
      // 51C91820 -> 51C-918.20
      return '${clean.substring(0, 3)}-${clean.substring(3, 6)}.${clean.substring(6)}';
    } else if (clean.length == 9) {
      // 29B112345 -> 29B1-123.45
      return '${clean.substring(0, 4)}-${clean.substring(4, 7)}.${clean.substring(7)}';
    } else if (clean.length == 7) {
      // 30A1234 -> 30A-1234
      return '${clean.substring(0, 3)}-${clean.substring(3)}';
    }
    return clean;
  }

  factory ViolationSubscription.fromJson(Map<String, dynamic> json) {
    return ViolationSubscription(
      id: json['id'] as int?,
      licensePlate: normalizePlate(json['licensePlate'] as String? ?? ''),
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'licensePlate': normalizePlate(licensePlate),
      'enabled': enabled,
    };
  }

  ViolationSubscription copyWith({
    int? id,
    String? licensePlate,
    bool? enabled,
  }) {
    return ViolationSubscription(
      id: id ?? this.id,
      licensePlate: licensePlate ?? this.licensePlate,
      enabled: enabled ?? this.enabled,
    );
  }
}

class ViolationSubscriptionRequest {
  final String licensePlate;
  final bool receiveNotificationsForBoth;

  ViolationSubscriptionRequest({
    required this.licensePlate,
    this.receiveNotificationsForBoth = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'licensePlate': ViolationSubscription.normalizePlate(licensePlate),
      'receiveNotificationsForBoth': receiveNotificationsForBoth,
    };
  }
}
