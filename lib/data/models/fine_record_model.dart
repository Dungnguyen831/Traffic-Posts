import 'dart:convert';

class ResolutionUnit {
  final String name;
  final String address;
  final String? phone;

  ResolutionUnit({
    required this.name,
    required this.address,
    this.phone,
  });

  factory ResolutionUnit.fromJson(Map<String, dynamic> json) {
    return ResolutionUnit(
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String?,
    );
  }
}

class FineDataInfo {
  final int total;
  final int chuaXuPhat;
  final int daXuPhat;
  final String latest;

  FineDataInfo({
    required this.total,
    required this.chuaXuPhat,
    required this.daXuPhat,
    required this.latest,
  });

  factory FineDataInfo.fromJson(Map<String, dynamic> json) {
    return FineDataInfo(
      total: (json['totalViolations'] ?? json['total'] ?? 0) as int,
      chuaXuPhat:
          (json['unprocessedViolations'] ?? json['chuaxuphat'] ?? 0) as int,
      daXuPhat: (json['processedViolations'] ?? json['daxuphat'] ?? 0) as int,
      latest: json['latest'] as String? ?? '',
    );
  }
}

class FineRecord {
  final int index;
  final String occurredAt;
  final String violationCode;
  final String violationDescription;
  final String location;
  final String penalty;
  final String status;
  final String statusCode;
  final String detectedBy;
  final List<ResolutionUnit> resolutionUnits;

  // Metadata
  final String bienKiemSoat;
  final String loaiPhuongTien;
  final String mauBien;

  FineRecord({
    this.index = 0,
    required this.occurredAt,
    this.violationCode = '',
    required this.violationDescription,
    required this.location,
    this.penalty = '',
    required this.status,
    this.statusCode = '',
    this.detectedBy = '',
    this.resolutionUnits = const [],
    this.bienKiemSoat = '',
    this.loaiPhuongTien = '',
    this.mauBien = '',
  });

  static final RegExp _cleanRegex = RegExp(r'^[\d.a-zA-Z]+\.\s*');

  String get cleanedViolationTitle {
    final raw = violationDescription;
    final match = _cleanRegex.firstMatch(raw);
    if (match != null && match.end < raw.length) {
      final afterCode = raw.substring(match.end).trimLeft();
      if (afterCode.isNotEmpty) return afterCode;
    }
    return raw.isNotEmpty ? raw : '—';
  }

  // Tương thích ngược với code cũ
  String get hanhViViPham => violationDescription;
  String get diaDiemViPham => location;
  String get thoiGianViPham => occurredAt;
  String get donViPhatHien => detectedBy;
  String get trangThai => status;
  List<String> get noiGiaiQuyet => resolutionUnits.map((u) {
        if (u.address.isNotEmpty) {
          return '${u.name}\n${u.address}';
        }
        return u.name;
      }).toList();

  /// Đã xử phạt = đã nộp phạt / đã giải quyết
  bool get isPaid {
    final sc = statusCode.toUpperCase().trim();
    if (sc == 'PROCESSED') return true;
    if (sc == 'UNPROCESSED') return false;

    final s = status.toLowerCase().trim();
    return s.contains('đã xử phạt') ||
        s.contains('đã nộp') ||
        s.contains('processed') ||
        s.contains('paid') ||
        s.contains('hoàn thành');
  }

  /// Format thời gian hiển thị: "2024-07-07T03:07:00" -> "03:07 - 07/07/2024"
  String get formattedOccurredAt {
    if (occurredAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(occurredAt);
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute - $day/$month/$year';
    } catch (_) {
      return occurredAt;
    }
  }

  factory FineRecord.fromJson(
    Map<String, dynamic> json, {
    String parentPlate = '',
    String parentVehicle = '',
  }) {
    // Parse resolutionUnits
    final rawUnits = json['resolutionUnits'] ??
        json['noiGiaiQuyet'] ??
        json['Nơi giải quyết vụ việc'];
    final List<ResolutionUnit> units = [];
    if (rawUnits is List) {
      for (final item in rawUnits) {
        if (item is Map<String, dynamic>) {
          units.add(ResolutionUnit.fromJson(item));
        } else if (item is String && item.trim().isNotEmpty) {
          units.add(ResolutionUnit(name: item.trim(), address: ''));
        }
      }
    }

    return FineRecord(
      index: json['index'] as int? ?? 0,
      occurredAt: json['occurredAt'] as String? ??
          json['violationTime'] as String? ??
          json['thoiGianViPham'] as String? ??
          json['Thời gian vi phạm'] as String? ??
          '',
      violationCode: json['violationCode'] as String? ?? '',
      violationDescription: json['violationDescription'] as String? ??
          json['violationAction'] as String? ??
          json['behavior'] as String? ??
          json['description'] as String? ??
          json['action'] as String? ??
          json['hanhViViPham'] as String? ??
          json['Hành vi vi phạm'] as String? ??
          '',
      location: json['location'] as String? ??
          json['violationLocation'] as String? ??
          json['diaDiemViPham'] as String? ??
          json['Địa điểm vi phạm'] as String? ??
          '',
      penalty: json['penalty'] as String? ?? '',
      status: json['status'] as String? ??
          json['violationStatus'] as String? ??
          json['trangThai'] as String? ??
          json['Trạng thái'] as String? ??
          '',
      statusCode: json['statusCode'] as String? ?? '',
      detectedBy: json['detectedBy'] as String? ??
          json['detectingUnit'] as String? ??
          json['donViPhatHien'] as String? ??
          json['Đơn vị phát hiện vi phạm'] as String? ??
          '',
      resolutionUnits: units,
      bienKiemSoat: json['licensePlate'] as String? ??
          json['bienKiemSoat'] as String? ??
          json['Biển kiểm soát'] as String? ??
          parentPlate,
      loaiPhuongTien: json['vehicleName'] as String? ??
          json['vehicleType'] as String? ??
          json['loaiPhuongTien'] as String? ??
          json['Loại phương tiện'] as String? ??
          parentVehicle,
      mauBien: json['mauBien'] as String? ?? json['Màu biển'] as String? ?? '',
    );
  }
}

class FineResponse {
  final int status;
  final String msg;
  final List<FineRecord> data;
  final FineDataInfo? dataInfo;
  final String? licensePlate;
  final String? vehicle;
  final String? vehicleName;
  final int? thisMonthViolations;
  final int? previousMonthViolations;

  FineResponse({
    required this.status,
    required this.msg,
    required this.data,
    this.dataInfo,
    this.licensePlate,
    this.vehicle,
    this.vehicleName,
    this.thisMonthViolations,
    this.previousMonthViolations,
  });

  /// status 1 = found violations, status 2 = no violations
  bool get hasViolations => data.isNotEmpty;
  bool get notFound => status == 2 || data.isEmpty;

  factory FineResponse.fromJson(Map<String, dynamic> json) {
    dynamic content = json['data'] ?? json;
    if (content is String) {
      try {
        content = jsonDecode(content);
      } catch (_) {}
    }

    Map<String, dynamic> dataMap = {};
    List<dynamic> rawRecords = [];

    if (content is Map<String, dynamic>) {
      dataMap = content;
      final rawV = content['violations'] ?? content['data'];
      if (rawV is List) {
        rawRecords = rawV;
      }
    } else if (content is List) {
      rawRecords = content;
    }

    final plate = dataMap['licensePlate'] as String? ?? '';
    final vehicleName = dataMap['vehicleName'] as String? ?? '';

    final List<FineRecord> records = rawRecords
        .map((e) => FineRecord.fromJson(
              e is Map<String, dynamic> ? e : {},
              parentPlate: plate,
              parentVehicle: vehicleName,
            ))
        .toList();

    final total = dataMap['totalViolations'] as int? ??
        dataMap['total'] as int? ??
        records.length;
    final chuaXuPhat = dataMap['unprocessedViolations'] as int? ??
        dataMap['chuaxuphat'] as int? ??
        records.where((r) => !r.isPaid).length;
    final daXuPhat = dataMap['processedViolations'] as int? ??
        dataMap['daxuphat'] as int? ??
        records.where((r) => r.isPaid).length;

    final info = FineDataInfo(
      total: total,
      chuaXuPhat: chuaXuPhat,
      daXuPhat: daXuPhat,
      latest: (dataMap['latest'] ?? '') as String,
    );

    final msg = json['message'] as String? ?? json['msg'] as String? ?? '';
    final int status = records.isEmpty ? 2 : 1;

    return FineResponse(
      status: status,
      msg: msg,
      data: records,
      dataInfo: info,
      licensePlate: plate.isNotEmpty ? plate : null,
      vehicle: dataMap['vehicle'] as String?,
      vehicleName: vehicleName.isNotEmpty ? vehicleName : null,
      thisMonthViolations: dataMap['thisMonthViolations'] as int?,
      previousMonthViolations: dataMap['previousMonthViolations'] as int?,
    );
  }
}
