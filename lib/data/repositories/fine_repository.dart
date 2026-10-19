import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../mock/mock_fines_data.dart';
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

    final cancelToken = CancelToken();
    Timer? timeoutTimer;

    // Đặt thời gian giới hạn 5 giây: Sau 5s nếu không trả về kết quả sẽ dừng call
    timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (!cancelToken.isCancelled) {
        cancelToken.cancel('Lookup request timed out after 5 seconds');
      }
    });

    try {
      final response = await _apiService.dio.post(
        '/violations/lookup',
        data: {
          'licensePlate': plate,
          'vehicle': vehicle,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
        cancelToken: cancelToken,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          if (!cancelToken.isCancelled) {
            cancelToken.cancel('Lookup request timed out after 5 seconds');
          }
          throw TimeoutException('Thời gian tra cứu quá 5 giây');
        },
      );

      timeoutTimer.cancel();

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

        // Nếu là biển số mock 51C91820 và kết quả từ API rỗng thì ưu tiên lấy mock data 10 lỗi
        if (isMockPlate(plate) && result.data.isEmpty) {
          final mockResult = getMockFineResponseFor51C91820(
            plate: plate,
            vehicle: vehicle,
          );
          _cache[cacheKey] = mockResult;
          return mockResult;
        }

        // Lưu vào cache để tối ưu tốc độ cho các lần bấm tiếp theo
        _cache[cacheKey] = result;
        if (_cache.length > 50) {
          _cache.remove(_cache.keys.first);
        }

        return result;
      } else {
        throw 'discovery_error_network'.tr;
      }
    } catch (e) {
      timeoutTimer.cancel();
      if (!cancelToken.isCancelled) {
        try {
          cancelToken.cancel('API call aborted');
        } catch (_) {}
      }

      // Sau 5s hoặc nếu không call được API:
      // 1. Đối với biển số 51C91820: Trả về mock data mặc định gồm 10 lỗi vi phạm
      if (isMockPlate(plate)) {
        final mockResult = getMockFineResponseFor51C91820(
          plate: plate,
          vehicle: vehicle,
        );
        _cache[cacheKey] = mockResult;
        return mockResult;
      }

      // 2. Đối với các biển số khác: Trả ra thông báo không có vi phạm như cũ
      final emptyResult = FineResponse(
        status: 2,
        msg: 'discovery_no_violations_title'.tr,
        data: [],
        licensePlate: plate,
        vehicle: vehicle,
      );
      return emptyResult;
    }
  }

  void clearCache() {
    _cache.clear();
  }
}
