import 'package:dio/dio.dart';

import '../models/user_info_model.dart';
import '../services/api_service.dart';

class FollowRepository {
  final ApiService _apiService = ApiService();

  /// Follow / Unfollow user (toggle – cùng 1 endpoint)
  Future<void> followUser(int userId) async {
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
  Future<List<UserInfoModel>> getFollowings() async {
    try {
      final response = await _apiService.dio.get('/follow/followings');
      final data = response.data;
      List<dynamic> list = [];
      if (data is Map && data['data'] is List) {
        list = data['data'] as List;
      } else if (data is List) {
        list = data;
      }
      return list
          .map((json) => UserInfoModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw e.response!.data['message'] ?? 'Không thể tải danh sách đang theo dõi';
      }
      throw 'Lỗi kết nối mạng';
    } catch (e) {
      throw e.toString();
    }
  }

  /// Lấy danh sách người theo dõi mình
  Future<List<UserInfoModel>> getFollowers() async {
    try {
      final response = await _apiService.dio.get('/follow/followers');
      final data = response.data;
      List<dynamic> list = [];
      if (data is Map && data['data'] is List) {
        list = data['data'] as List;
      } else if (data is List) {
        list = data;
      }
      return list
          .map((json) => UserInfoModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw e.response!.data['message'] ?? 'Không thể tải danh sách người theo dõi';
      }
      throw 'Lỗi kết nối mạng';
    } catch (e) {
      throw e.toString();
    }
  }
}
