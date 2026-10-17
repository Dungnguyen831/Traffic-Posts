import 'package:dio/dio.dart';

import '../datasources/violation_subscription_datasource.dart';
import '../models/violation_subscription_model.dart';

class ViolationSubscriptionRepository {
  final ViolationSubscriptionRemoteDataSource _dataSource;

  ViolationSubscriptionRepository({
    ViolationSubscriptionRemoteDataSource? dataSource,
  }) : _dataSource =
            dataSource ?? ViolationSubscriptionRemoteDataSourceImpl();

  /// Lấy danh sách biển số đã đăng ký theo dõi
  Future<List<ViolationSubscription>> getSubscriptions() async {
    try {
      return await _dataSource.getSubscriptions();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Không thể tải danh sách theo dõi biển số');
    } catch (e) {
      throw e.toString();
    }
  }

  /// Đăng ký theo dõi hoặc cập nhật tùy chọn nhận thông báo
  Future<String> subscribe({
    required String licensePlate,
    required bool receiveNotificationsForBoth,
  }) async {
    final cleanPlate = ViolationSubscription.normalizePlate(licensePlate);
    if (!ViolationSubscription.isValidPlate(cleanPlate)) {
      throw 'Biển số xe không đúng định dạng hợp lệ';
    }

    try {
      final request = ViolationSubscriptionRequest(
        licensePlate: cleanPlate,
        receiveNotificationsForBoth: receiveNotificationsForBoth,
      );
      return await _dataSource.subscribe(request);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Không thể đăng ký theo dõi biển số');
    } catch (e) {
      throw e.toString();
    }
  }

  /// Hủy theo dõi một biển số xe cụ thể
  Future<String> unsubscribe(String licensePlate) async {
    final cleanPlate = ViolationSubscription.normalizePlate(licensePlate);
    if (cleanPlate.isEmpty) {
      throw 'Biển số xe không được để trống';
    }

    try {
      return await _dataSource.unsubscribe(cleanPlate);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Không thể hủy theo dõi biển số $cleanPlate');
    } catch (e) {
      throw e.toString();
    }
  }

  /// Đổi sang biển số mới: Hủy theo dõi biển cũ (nếu có) và đăng ký biển mới
  Future<String> changePlate({
    required String oldPlate,
    required String newPlate,
    required bool receiveNotificationsForBoth,
  }) async {
    final cleanOld = ViolationSubscription.normalizePlate(oldPlate);
    final cleanNew = ViolationSubscription.normalizePlate(newPlate);

    if (!ViolationSubscription.isValidPlate(cleanNew)) {
      throw 'Biển số xe không đúng định dạng hợp lệ';
    }

    if (cleanOld.isNotEmpty && cleanOld != cleanNew) {
      try {
        await _dataSource.unsubscribe(cleanOld);
      } catch (_) {
        // Bỏ qua nếu biển cũ không tồn tại hoặc đã bị hủy trước đó
      }
    }

    final request = ViolationSubscriptionRequest(
      licensePlate: cleanNew,
      receiveNotificationsForBoth: receiveNotificationsForBoth,
    );

    try {
      return await _dataSource.subscribe(request);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Không thể cập nhật biển số mới');
    } catch (e) {
      throw e.toString();
    }
  }

  /// Hủy toàn bộ đăng ký theo dõi
  Future<String> unsubscribeAll() async {
    try {
      return await _dataSource.unsubscribeAll();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Không thể hủy toàn bộ danh sách theo dõi');
    } catch (e) {
      throw e.toString();
    }
  }

  /// Xóa trackers theo dõi vi phạm DELETE /violations/trackers
  Future<String> deleteTrackers() async {
    try {
      return await _dataSource.deleteTrackers();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Không thể xóa trackers theo dõi');
    } catch (e) {
      throw e.toString();
    }
  }

  String _handleDioError(DioException e, String defaultMessage) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      } else if (data is String && data.isNotEmpty) {
        return data;
      }
    }
    return e.message ?? defaultMessage;
  }
}
