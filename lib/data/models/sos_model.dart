class SosResponseDTO {
  final String sosId;
  final double? latitude;
  final double? longitude;
  final String? phoneNumber;
  final String? address;
  final String? note;
  final DateTime? timestamp;
  final String? status;
  final int? userId;
  final String? username;

  SosResponseDTO({
    required this.sosId,
    this.latitude,
    this.longitude,
    this.phoneNumber,
    this.address,
    this.note,
    this.timestamp,
    this.status,
    this.userId,
    this.username,
  });

  factory SosResponseDTO.fromJson(Map<String, dynamic> json) {
    return SosResponseDTO(
      sosId: json['sosId'] as String? ?? json['id']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      phoneNumber: json['phoneNumber'] as String? ?? json['phone'] as String?,
      address: json['address'] as String?,
      note: json['note'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
      status: json['status'] as String?,
      userId: (json['userId'] as num?)?.toInt() ??
          (json['user_id'] as num?)?.toInt() ??
          (json['idUser'] as num?)?.toInt() ??
          int.tryParse(json['userId']?.toString() ?? '') ??
          int.tryParse(json['user_id']?.toString() ?? ''),
      username: json['username'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'sosId': sosId,
    'latitude': latitude,
    'longitude': longitude,
    'phoneNumber': phoneNumber,
    'address': address,
    'note': note,
    'timestamp': timestamp?.toIso8601String(),
    'status': status,
    'userId': userId,
    'username': username,
  };
}
