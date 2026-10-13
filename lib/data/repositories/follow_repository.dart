import 'package:dio/dio.dart';

import '../../config/demo_config.dart';
import '../services/api_service.dart';

class FollowRepository {
  final ApiService _apiService = ApiService();

  /// Follow / Unfollow user (toggle – cùng 1 endpoint)
  Future<void> followUser(int userId) async {
    if (DemoConfig.isDemoMode) return;
    try {
      await _apiService.dio.post('/follow/$userId');
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw e.response!.data['message'] ?? 'Không thể thực hiện hành động';
      }
      throw 'Lỗi kết nối mạng';
    } catch (e) {
      throw e.toString();
    }
  }

  /// Lấy danh sách đang theo dõi
  Future<dynamic> getFollowings() async {
    try {
      final response = await _apiService.dio.get('/follow/followings');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw e.response!.data['message'] ?? 'Không thể tải danh sách';
      }
      throw 'Lỗi kết nối mạng';
    } catch (e) {
      throw e.toString();
    }
  }

  /// Lấy danh sách người theo dõi mình
  Future<dynamic> getFollowers() async {
    try {
      final response = await _apiService.dio.get('/follow/followers');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw e.response!.data['message'] ?? 'Không thể tải danh sách';
      }
      throw 'Lỗi kết nối mạng';
    } catch (e) {
      throw e.toString();
    }
  }
}
