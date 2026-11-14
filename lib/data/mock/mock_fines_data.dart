import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

import '../models/fine_record_model.dart';

/// Kiểm tra biển số có phải là biển số mock 51C91820 hay không
/// Hỗ trợ tất cả các định dạng: 51C91820, 51C-918.20, 51c91820, 51C 91820...
bool isMockPlate(String? plate) {
  if (plate == null || plate.trim().isEmpty) return false;
  final clean = plate.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
  return clean == '51C91820';
}

FineResponse? _cachedMockFineResponse;

/// Đọc và trả về FineResponse từ file mock_data_phatnguoi.txt
Future<FineResponse> getMockFineResponseFor51C91820({
  String? plate,
  String? vehicle,
}) async {
  if (_cachedMockFineResponse == null) {
    String jsonStr;
    try {
      jsonStr = await rootBundle.loadString('mock_data_phatnguoi.txt');
    } catch (_) {
      try {
        jsonStr =
            await rootBundle.loadString('assets/json/mock_data_phatnguoi.txt');
      } catch (_) {
        final file = File('mock_data_phatnguoi.txt');
        jsonStr = await file.readAsString();
      }
    }

    final dynamic decoded = jsonDecode(jsonStr);
    _cachedMockFineResponse = FineResponse.fromJson(
      decoded is Map<String, dynamic> ? decoded : {},
    );
  }

  final base = _cachedMockFineResponse!;
  final resolvedPlate = (plate != null && plate.trim().isNotEmpty)
      ? plate.trim().toUpperCase()
      : (base.licensePlate ?? '51C91820');

  return FineResponse(
    status: base.status,
    msg: base.msg,
    data: base.data,
    dataInfo: base.dataInfo,
    licensePlate: resolvedPlate,
    vehicle: vehicle ?? base.vehicle,
    vehicleName: base.vehicleName,
    thisMonthViolations: base.thisMonthViolations,
    previousMonthViolations: base.previousMonthViolations,
  );
}
