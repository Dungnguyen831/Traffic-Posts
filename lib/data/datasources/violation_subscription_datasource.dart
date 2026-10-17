import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/violation_subscription_model.dart';
import '../services/api_service.dart';

abstract class ViolationSubscriptionRemoteDataSource {
  Future<List<ViolationSubscription>> getSubscriptions();
  Future<String> subscribe(ViolationSubscriptionRequest request);
  Future<String> unsubscribe(String licensePlate);
  Future<String> unsubscribeAll();
  Future<String> deleteTrackers();
}

class ViolationSubscriptionRemoteDataSourceImpl
    implements ViolationSubscriptionRemoteDataSource {
  final ApiService _apiService;

  ViolationSubscriptionRemoteDataSourceImpl({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  @override
  Future<List<ViolationSubscription>> getSubscriptions() async {
    final response = await _apiService.dio.get('/violations/subscription');

    final rawData = _decodeData(response.data);

    if (rawData is Map<String, dynamic>) {
      if (rawData['success'] == false) {
        throw rawData['message'] ?? 'Không thể lấy danh sách theo dõi biển số';
      }

      final list = rawData['data'];
      if (list is List) {
        return list
            .map((e) => ViolationSubscription.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    }
    return [];
  }

  @override
  Future<String> subscribe(ViolationSubscriptionRequest request) async {
    final response = await _apiService.dio.post(
      '/violations/subscription',
      data: request.toJson(),
    );

    return _parseMessage(response.data, 'Thao tác thành công', 'Đăng ký theo dõi thất bại');
  }

  @override
  Future<String> unsubscribe(String licensePlate) async {
    final cleanPlate = Uri.encodeComponent(ViolationSubscription.normalizePlate(licensePlate));
    try {
      final response = await _apiService.dio.delete(
        '/violations/subscription/$cleanPlate',
      );
      return _parseMessage(response.data, 'Đã hủy theo dõi biển số', 'Hủy theo dõi thất bại');
    } on DioException catch (e) {
      // Fallback sang endpoint DELETE /violations/subscription nếu route có path variable không tồn tại hoặc bị từ chối
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        final fallbackResponse = await _apiService.dio.delete(
          '/violations/subscription',
        );
        return _parseMessage(fallbackResponse.data, 'Đã hủy theo dõi biển số', 'Hủy theo dõi thất bại');
      }
      rethrow;
    }
  }

  @override
  Future<String> unsubscribeAll() async {
    final response = await _apiService.dio.delete(
      '/violations/subscription',
    );

    return _parseMessage(response.data, 'Đã hủy toàn bộ theo dõi', 'Hủy toàn bộ theo dõi thất bại');
  }

  @override
  Future<String> deleteTrackers() async {
    final response = await _apiService.dio.delete(
      '/violations/trackers',
    );

    return _parseMessage(response.data, 'Đã xóa trackers theo dõi', 'Xóa trackers thất bại');
  }

  dynamic _decodeData(dynamic raw) {
    if (raw is String) {
      try {
        return jsonDecode(raw);
      } catch (_) {}
    }
    return raw;
  }

  String _parseMessage(dynamic raw, String defaultSuccess, String defaultError) {
    final data = _decodeData(raw);
    if (data is Map<String, dynamic>) {
      if (data['success'] == false) {
        throw data['message'] ?? defaultError;
      }
      return (data['message'] ?? defaultSuccess).toString();
    }
    return defaultSuccess;
  }
}
