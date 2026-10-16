import 'dart:convert';

import '../models/violation_subscription_model.dart';
import '../services/api_service.dart';

abstract class ViolationSubscriptionRemoteDataSource {
  Future<List<ViolationSubscription>> getSubscriptions();
  Future<String> subscribe(ViolationSubscriptionRequest request);
  Future<String> unsubscribe(String licensePlate);
  Future<String> unsubscribeAll();
}

class ViolationSubscriptionRemoteDataSourceImpl
    implements ViolationSubscriptionRemoteDataSource {
  final ApiService _apiService;

  ViolationSubscriptionRemoteDataSourceImpl({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  @override
  Future<List<ViolationSubscription>> getSubscriptions() async {
    final response = await _apiService.dio.get('/violations/subscription');

    dynamic rawData = response.data;
    if (rawData is String) {
      try {
        rawData = jsonDecode(rawData);
      } catch (_) {}
    }

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

    dynamic rawData = response.data;
    if (rawData is String) {
      try {
        rawData = jsonDecode(rawData);
      } catch (_) {}
    }

    if (rawData is Map<String, dynamic>) {
      if (rawData['success'] == false) {
        throw rawData['message'] ?? 'Đăng ký theo dõi thất bại';
      }
      return (rawData['message'] ?? 'Thao tác thành công').toString();
    }
    return 'Thao tác thành công';
  }

  @override
  Future<String> unsubscribe(String licensePlate) async {
    final cleanPlate = ViolationSubscription.normalizePlate(licensePlate);
    final response = await _apiService.dio.delete(
      '/violations/subscription/$cleanPlate',
    );

    dynamic rawData = response.data;
    if (rawData is String) {
      try {
        rawData = jsonDecode(rawData);
      } catch (_) {}
    }

    if (rawData is Map<String, dynamic>) {
      if (rawData['success'] == false) {
        throw rawData['message'] ?? 'Hủy theo dõi thất bại';
      }
      return (rawData['message'] ?? 'Đã hủy theo dõi biển số').toString();
    }
    return 'Đã hủy theo dõi biển số';
  }

  @override
  Future<String> unsubscribeAll() async {
    final response = await _apiService.dio.delete(
      '/violations/subscription',
    );

    dynamic rawData = response.data;
    if (rawData is String) {
      try {
        rawData = jsonDecode(rawData);
      } catch (_) {}
    }

    if (rawData is Map<String, dynamic>) {
      if (rawData['success'] == false) {
        throw rawData['message'] ?? 'Hủy toàn bộ theo dõi thất bại';
      }
      return (rawData['message'] ?? 'Đã hủy toàn bộ theo dõi').toString();
    }
    return 'Đã hủy toàn bộ theo dõi';
  }
}
