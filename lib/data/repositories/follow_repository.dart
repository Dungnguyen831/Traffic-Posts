import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../config/demo_config.dart';
import '../models/user_info_model.dart';
import '../services/api_service.dart';

class FollowRepository {
  final ApiService _apiService = ApiService();

  static final List<UserInfoModel> _demoFollowers =
      DemoConfig.getSampleRankingUsers()
          .where((u) => u.id != 1)
          .map((u) => u.copyWith(follow: u.follow ?? true))
          .toList();

  static final List<UserInfoModel> _demoFollowings =
      DemoConfig.getSampleRankingUsers()
          .where((u) => u.id != 1 && (u.follow ?? false))
          .map((u) => u.copyWith(follow: true))
          .toList();

  /// Follow / Unfollow user (toggle – cùng 1 endpoint)
  Future<void> followUser(int userId) async {
    if (DemoConfig.isDemoMode) {
      final existingIdx = _demoFollowings.indexWhere((u) => u.id == userId);
      if (existingIdx != -1) {
        _demoFollowings.removeAt(existingIdx);
      } else {
        final followerMatch =
            _demoFollowers.firstWhereOrNull((u) => u.id == userId) ??
            DemoConfig.getSampleRankingUsers()
                .firstWhereOrNull((u) => u.id == userId);
        if (followerMatch != null) {
          _demoFollowings.add(followerMatch.copyWith(follow: true));
        }
      }
      return;
    }
    try {
      await _apiService.dio.post('/follow/$userId');
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw e.response!.data['message'] ?? 'action_failed'.tr;
      }
      throw 'network_error'.tr;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Lấy danh sách đang theo dõi
  Future<List<UserInfoModel>> getFollowings() async {
    if (DemoConfig.isDemoMode) {
      return List<UserInfoModel>.from(_demoFollowings);
    }
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
        throw e.response!.data['message'] ?? 'action_failed'.tr;
      }
      throw 'network_error'.tr;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Lấy danh sách người theo dõi mình
  Future<List<UserInfoModel>> getFollowers() async {
    if (DemoConfig.isDemoMode) {
      return List<UserInfoModel>.from(_demoFollowers);
    }
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
        throw e.response!.data['message'] ?? 'action_failed'.tr;
      }
      throw 'network_error'.tr;
    } catch (e) {
      throw e.toString();
    }
  }
}
