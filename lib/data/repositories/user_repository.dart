import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:http_parser/http_parser.dart';

import '../models/profile_request.dart';
import '../services/api_service.dart';
import '../../data/models/user_info_model.dart';
import '../models/traffic_post_model.dart';

class UserRepository {
  final ApiService _apiService = ApiService();

  // 1. Lấy thông tin (GET)
  Future<ProfileRequest> getProfile() async {
    try {
      final response = await _apiService.dio.get('/users/profile');

      final rawData = response.data;
      final Map<String, dynamic> data = (rawData is Map && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'] as Map)
          : (rawData is Map
              ? Map<String, dynamic>.from(rawData)
              : <String, dynamic>{});

      return ProfileRequest.fromJson(data);
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw e.response!.data['message'] ?? 'profile_load_error'.tr;
      }
      throw 'profile_network_error'.tr;
    } catch (e) {
      throw e.toString();
    }
  }

  // 2. Cập nhật thông tin (PUT)
  Future<void> updateProfile(
    ProfileRequest user,
    File? avatarFile, {
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      String jsonProfile = jsonEncode(user.toJson());
      final Map<String, dynamic> formDataMap = {
        'profile': MultipartFile.fromString(
          jsonProfile,
          contentType: MediaType('application', 'json'),
        ),
      };
      if (avatarFile != null) {
        String fileName = avatarFile.path.split('/').last;
        formDataMap['avatar'] = await MultipartFile.fromFile(
          avatarFile.path,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        );
      }

      final formData = FormData.fromMap(formDataMap);
      await _apiService.dio.put(
        '/users/profile',
        data: formData,
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw e.response!.data['message'] ?? 'profile_update_error'.tr;
      }
      throw 'profile_network_error'.tr;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Lấy thông tin hiển thị Trang cá nhân (Bao gồm UserInfo và Danh sách bài viết)
  Future<Map<String, dynamic>> getUserProfile(
    String userId, {
    int page = 0, // ✅ KHAI BÁO THÊM THAM SỐ PAGE
    int size = 10, // ✅ KHAI BÁO THÊM THAM SỐ SIZE
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/users/$userId/profile',
        // ✅ ĐẨY PAGE VÀ SIZE LÊN BACKEND THÔNG QUA QUERY PARAMETERS
        queryParameters: {
          'page': page,
          'size': size,
        },
      );

      // 1. Trích xuất data
      final data = response.data['data'] ?? response.data;
      if (data == null) throw 'profile_load_error'.tr;

      // 2. Parse phần UserInfo
      if (data['userInfo'] == null) throw 'profile_load_error'.tr;
      final userInfo = UserInfoModel.fromJson(data['userInfo'] as Map<String, dynamic>);

      // 3. Parse phần Bài viết (Lấy từ posts -> content do API dùng phân trang)
      List<TrafficPostModel> postsList = [];
      int rawPostCount = 0;
      final resolvedUserId = userInfo.id?.toString() ?? userId;
      if (data['posts'] != null && data['posts']['content'] != null) {
        final rawList = data['posts']['content'] as List;
        rawPostCount = rawList.length;
        postsList = rawList
            .map((json) {
              final post =
                  TrafficPostModel.fromJson(json as Map<String, dynamic>);
              if (post.userId == null || post.userId!.trim().isEmpty) {
                return post.copyWith(userId: resolvedUserId);
              }
              return post;
            })
            .where((post) => post.isVisible)
            .toList();
      }

      return {
        'userInfo': userInfo,
        'posts': postsList,
        'rawPostCount': rawPostCount,
      };
      
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw e.response!.data['message'] ?? 'profile_load_error'.tr;
      }
      throw 'network_error_retry'.tr;
    } catch (e) {
      throw 'Có lỗi xảy ra: ${e.toString()}';
    }
  }

  // 4. Lấy bảng xếp hạng uy tín (GET /users/ranking)
  Future<List<UserInfoModel>> getRanking({int page = 0, int size = 20}) async {
    try {
      final response = await _apiService.dio.get(
        '/users/ranking',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );

      final data = response.data['data'] ?? response.data;
      if (data == null) return [];

      final content = data is Map ? data['content'] : data;
      if (content is List) {
        return content
            .map((e) => UserInfoModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw e.response!.data['message'] ?? 'reputation_ranking_empty'.tr;
      }
      throw 'profile_network_error'.tr;
    } catch (e) {
      throw e.toString();
    }
  }
}
