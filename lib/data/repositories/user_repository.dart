import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../config/demo_config.dart';
import '../../services/storage_service.dart';
import '../models/profile_request.dart';
import '../services/api_service.dart';
import '../../data/models/user_info_model.dart';
import '../models/traffic_post_model.dart';

class UserRepository {
  final ApiService _apiService = ApiService();

  // 1. Lấy thông tin (GET)
  Future<ProfileRequest> getProfile() async {
    if (DemoConfig.isDemoMode) {
      final storage = StorageService.to;
      return ProfileRequest(
        fullname: storage.getFullName() ?? 'Nguyễn Anh Dũng',
        email: 'dung.nguyen@flowly.vn',
        phoneNumber: storage.getPhoneNumber() ?? '0983168888',
        province: storage.getProvince() ?? 'Hà Nội',
        relativePhone: storage.getRelativePhone() ?? '0988888888',
        avatarUrl: DemoConfig.demoUserAvatar,
      );
    }
    try {
      final response = await _apiService.dio.get('/users/profile');

      // Nếu API trả về thành công 200 OK
      return ProfileRequest.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw e.response!.data['message'] ?? 'Không thể tải thông tin cá nhân';
      }
      throw 'Lỗi kết nối khi lấy thông tin';
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
    if (DemoConfig.isDemoMode) {
      await StorageService.to.saveUserInfo(
        fullname: user.fullname,
        province: user.province,
        relativePhone: user.relativePhone,
        phoneNumber: user.phoneNumber,
      );
      return;
    }
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
        throw e.response!.data['message'] ?? 'Cập nhật thất bại';
      }
      throw 'Lỗi kết nối khi cập nhật';
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
    if (DemoConfig.isDemoMode) {
      final storage = StorageService.to;
      return {
        'userInfo': UserInfoModel(
          id: 1,
          fullname: storage.getFullName() ?? 'Nguyễn Anh Dũng',
          avatarUrl: DemoConfig.demoUserAvatar,
          follow: false,
          followersCount: 128,
          followingsCount: 45,
        ),
        'posts': DemoConfig.getInitialSamplePosts(),
      };
    }
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
      if (data == null) throw 'Không có dữ liệu trả về từ server';

      // 2. Parse phần UserInfo
      if (data['userInfo'] == null) throw 'Không tìm thấy thông tin người dùng';
      final userInfo = UserInfoModel.fromJson(data['userInfo'] as Map<String, dynamic>);

      // 3. Parse phần Bài viết (Lấy từ posts -> content do API dùng phân trang)
      List<TrafficPostModel> postsList = [];
      if (data['posts'] != null && data['posts']['content'] != null) {
        postsList = (data['posts']['content'] as List)
            .map((json) => TrafficPostModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return {
        'userInfo': userInfo,
        'posts': postsList,
      };
      
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        throw e.response!.data['message'] ?? 'Không thể tải trang cá nhân';
      }
      throw 'Lỗi kết nối mạng. Vui lòng kiểm tra lại Internet.';
    } catch (e) {
      throw 'Có lỗi xảy ra: ${e.toString()}';
    }
  }
}
