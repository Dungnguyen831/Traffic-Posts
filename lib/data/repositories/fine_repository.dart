import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../models/fine_record_model.dart';
import '../services/api_service.dart';

class FineRepository {
  final ApiService _apiService = ApiService();

  // Cache in-memory theo định dạng "$licensePlate-$vehicle"
  static final Map<String, FineResponse> _cache = {};

  Future<FineResponse> lookupFines(
    String licensePlate, {
    String vehicle = '1',
    bool forceRefresh = false,
  }) async {
    final plate = licensePlate.trim().toUpperCase();
    final cacheKey = '$plate-$vehicle';

    // Nếu đã tra cứu trước đó và không yêu cầu refresh -> trả về ngay (0ms, không lag)
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final response = await _apiService.dio.post(
        '/violations/lookup',
        data: {
          'licensePlate': plate,
          'vehicle': vehicle,
        },
      );

      dynamic rawData = response.data;
      if (rawData is String) {
        try {
          rawData = jsonDecode(rawData);
        } catch (_) {}
      }

      if (rawData is Map<String, dynamic>) {
        if (rawData['success'] == false) {
          throw rawData['message'] ?? 'discovery_error_generic'.tr;
        }
        final result = FineResponse.fromJson(rawData);

        // Lưu vào cache để tối ưu tốc độ cho các lần bấm tiếp theo
        _cache[cacheKey] = result;
        if (_cache.length > 50) {
          _cache.remove(_cache.keys.first);
        }

        return result;
      } else {
        throw 'discovery_error_network'.tr;
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        final err = e.response!.data;
        if (err is Map && err['message'] != null) {
          throw err['message'].toString();
        }
      }
      throw e.message ?? 'discovery_error_network'.tr;
    }
  }

  void clearCache() {
    _cache.clear();
  }
}
